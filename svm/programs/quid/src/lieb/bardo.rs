
use anchor_lang::prelude::*;
use anchor_spl::associated_token::AssociatedToken;
use anchor_spl::token_interface::{ 
    self, Mint, TokenAccount, 
    TokenInterface, TransferChecked 
};
use std::str::FromStr;
use crate::stay::*;
use crate::etc::{
    USD_STAR, HEX_MAP,
    ACCOUNT_MAP,
    MAX_AGE, 
    PithyQuip
};
use pyth_solana_receiver_sdk::price_update::{
         get_feed_id_from_hex, PriceUpdateV2};

#[derive(Accounts)]
pub struct Liquidate<'info> {
    #[account(mut)]
    pub liquidator: Signer<'info>,
    // Obiwan Kenobi, убиван who not bleed

    /// CHECK: raw account only to validate ownership;
    /// no reads/writes or assumptions beyond `.key()`
    pub liquidating: AccountInfo<'info>,
    pub mint: InterfaceAccount<'info, Mint>,
    
    #[account(mut, 
        seeds = [mint.key().as_ref()],
        bump,
    )]  
    pub bank: Account<'info, Depository>,
    
    #[account(mut, 
        seeds = [b"vault", mint.key().as_ref()],
        bump, 
    )]  
    pub bank_token_account: InterfaceAccount<'info, TokenAccount>,

    #[account(mut, 
        seeds = [liquidating.key().as_ref()],
        bump,
    )]  
    pub customer_account: Account<'info, Depositor>,

    #[account( 
        init_if_needed, 
        payer = liquidator,
        associated_token::mint = mint, 
        associated_token::authority = liquidator,
        associated_token::token_program = token_program,
        constraint = liquidator_token_account.owner == liquidator.key() 
    )] 
    pub liquidator_token_account: InterfaceAccount<'info, TokenAccount>,
    pub token_program: Interface<'info, TokenInterface>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}

// "It's like inch by inch...step by step...closin' in on your position
//  in small doses...when things have gotten closer to the sun," she said, 
// "don't think I'm pushing you away as ⚡️ strikes...court lights get dim..."
// The file is called bardo in reference to Diotima’s idea of the in-between,
// or metaxy: wasn’t limited just to ignorance and wisdom. She called into 
// question all kinds of binary oppositions, including between good and evil,
// beautiful and ugly, divine and mortal. Given how little we have to go on,
// it is hard to fully reconstruct Diotima’s philosophy; but it seems that 
// for her most of the interesting stuff happens in these in-between spaces,
// insecurities perfection or perturbation theory in quantum securities... 
// in the middle-ground...the kinds of distinctions that philosophers make 
// between good and evil ignore how entangled these oppositions really are.
pub fn amortise(ctx: Context<Liquidate>, ticker: String) -> Result<()> { 
    // require_keys_eq!(ctx.accounts.mint.key(), USD_STAR, PithyQuip::InvalidMint); 
    // ^ only for deployment, comment out for anchor test --skip-local-validator
    let Banks = &mut ctx.accounts.bank;
    let customer = &mut ctx.accounts.customer_account;
    require_keys_eq!(customer.owner, ctx.accounts.liquidating.key(), PithyQuip::InvalidUser);
    
    let transfer_cpi_accounts = TransferChecked {
        from: ctx.accounts.bank_token_account.to_account_info(),
        mint: ctx.accounts.mint.to_account_info(),
        to: ctx.accounts.liquidator_token_account.to_account_info(),
        authority: ctx.accounts.bank_token_account.to_account_info(),
    };
    let cpi_program = ctx.accounts.token_program.to_account_info();
    let mint_key = ctx.accounts.mint.key();
    let signer_seeds: &[&[&[u8]]] = &[
        &[ b"vault", mint_key.as_ref(),
            &[ctx.bumps.bank_token_account],
        ],
    ]; 
    let cpi_ctx = CpiContext::new(
    cpi_program, transfer_cpi_accounts).with_signer(signer_seeds);
    let decimals = ctx.accounts.mint.decimals;

    let t: &str = ticker.as_str(); let right_now = Clock::get()?.unix_timestamp;
    let mut key: &str = ACCOUNT_MAP.get(t).ok_or(PithyQuip::UnknownSymbol)?;
    let mut hex: &str = HEX_MAP.get(t).ok_or(PithyQuip::UnknownSymbol)?;
    let first: &AccountInfo = &ctx.remaining_accounts[0];
    let first_key = first.key.to_string(); 
    if first_key != key {
        return Err(PithyQuip::UnknownSymbol.into());
    }
    let mut first_data: &[u8] = &first.try_borrow_data()?;
    let price_update = PriceUpdateV2::try_deserialize(&mut first_data)?;
    
    let feed_id = get_feed_id_from_hex(hex)?;
    let price = price_update.get_price_no_older_than(&Clock::get()?, MAX_AGE, &feed_id)?;
    let adjusted_price = (price.price as f64) * 10f64.powi(price.exponent as i32);

    let (mut delta, mut interest) = customer.reposition(t, 
        0, adjusted_price as u64, right_now, Banks.interest_rate)?;
    
    require!(delta != 0, PithyQuip::NotUndercollateralised);

    Banks.total_deposits += interest;
    interest = (delta / 250) as u64;
    if delta < 0 { // take profit on behalf all depostors, at the expense of one... 
        delta *= -1; // < remove symbolic meaning, converting it to a usable number...
        delta -= interest as i64; // < commission for the liquidator (just over 0.5%)
        Banks.total_deposits += delta as u64;
    }
    else if delta > 0 {
        // before we try to deduct from depository
        // attemp to salvage amount from depositor
        let mut prices: Vec<u64> = Vec::new();
        for i in 0..customer.balances.len() {
            let bytes = customer.balances[i].ticker.clone();
            
            let len = bytes.iter().position(|&b| b == 0)
                                    .unwrap_or(bytes.len());

            let t = std::str::from_utf8(&bytes[..len])
                .expect("Invalid UTF-8");
            
            hex = HEX_MAP.get(t).ok_or(PithyQuip::UnknownSymbol)?;
            key = ACCOUNT_MAP.get(t).ok_or(PithyQuip::UnknownSymbol)?;

            let pubkey = Pubkey::from_str(key).map_err(|_| PithyQuip::UnknownSymbol)?;
            let acct_info: &AccountInfo = ctx.remaining_accounts
                .iter().find(|a| a.key == &pubkey).ok_or(PithyQuip::Tickers)?;

            let mut data: &[u8] = &acct_info.try_borrow_data()?;
            let price_update = PriceUpdateV2::try_deserialize(&mut data)?;
            
            let feed_id = get_feed_id_from_hex(hex)?;
            let price = price_update.get_price_no_older_than(
                        &Clock::get()?, MAX_AGE, &feed_id)?;
            
            let adjusted_price = (price.price as f64) * 10f64.powi(price.exponent as i32);
            prices.push(adjusted_price as u64);
        }
        let remainder = customer.renege(None, -delta as i64, Some(&prices), right_now)? as i64;
        customer.deposited_usd_star += (delta - remainder) as u64; // < return amount taken in reposition, now taken from positions...
        let shares_to_remove = (remainder.abs() as f64 / Banks.total_deposits as f64) * Banks.total_deposit_shares as f64;
        customer.deposited_usd_star_shares -= shares_to_remove as u64;
        Banks.total_deposit_shares -= shares_to_remove as u64;
        Banks.total_deposits -= remainder as u64;
    }   token_interface::transfer_checked(cpi_ctx,
                interest, decimals)?;
    Ok(())
}
         