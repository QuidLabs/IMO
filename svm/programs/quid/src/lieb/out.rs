
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
pub struct Withdraw<'info> {
    #[account(mut)]
    pub signer: Signer<'info>,
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
        seeds = [signer.key().as_ref()],
        bump,
    )]  
    pub customer_account: Account<'info, Depositor>,
    
    #[account(mut,
        associated_token::mint = mint, 
        associated_token::authority = signer,
        associated_token::token_program = token_program,
        constraint = customer_token_account.owner == signer.key() 
    )]
    pub customer_token_account: InterfaceAccount<'info, TokenAccount>, 
    pub token_program: Interface<'info, TokenInterface>,
    pub associated_token_program: Program<'info, AssociatedToken>,
    pub system_program: Program<'info, System>,
}

pub fn handle_out(ctx: Context<Withdraw>, 
    mut amount: i64, ticker: String, exposure: bool) -> Result<()> { 
    require!(amount != 0, PithyQuip::InvalidAmount);
    
    // require_keys_eq!(ctx.accounts.mint.key(), USD_STAR, PithyQuip::InvalidMint);
    // ^ only for deployment, comment out for anchor test --skip-local-validator

    let Banks = &mut ctx.accounts.bank;
    let customer = &mut ctx.accounts.customer_account;
    require_keys_eq!(customer.owner, ctx.accounts.signer.key(), PithyQuip::InvalidUser);
    
    let transfer_cpi_accounts = TransferChecked {
        from: ctx.accounts.bank_token_account.to_account_info(),
        mint: ctx.accounts.mint.to_account_info(),
        to: ctx.accounts.customer_token_account.to_account_info(),
        authority: ctx.accounts.bank_token_account.to_account_info(),
    };
    let cpi_program = ctx.accounts.token_program.to_account_info();
    let mint_key = ctx.accounts.mint.key();
    let signer_seeds: &[&[&[u8]]] = &[
        &[ b"vault", mint_key.as_ref(),
            &[ctx.bumps.bank_token_account],
        ],
    ]; 
    let right_now = Clock::get()?.unix_timestamp;
    let decimals = ctx.accounts.mint.decimals;
    let cpi_ctx = CpiContext::new(cpi_program, 
            transfer_cpi_accounts).with_signer(signer_seeds);
    
    let mut time_delta = right_now - Banks.last_updated;
    Banks.total_deposit_seconds += (time_delta as u64 * Banks.total_deposits) as u128;
    Banks.last_updated = right_now; 

    let mut amt: u64 = 0;
    if ticker.is_empty() { // withdrawal of $ deposits...
    // returns your pro-rata share of the pool, plus your 
    // accrued yield — net of any losses for honoring TPs
        require!(amount < 0, PithyQuip::InvalidAmount);
        if exposure { // first empty credit accounts,
        // prior to withdrawing from Depository...
            let mut prices: Vec<u64> = Vec::new();
            let mut hex: &str; let mut key: &str;
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
            amt = amount.abs() as u64; 
            // amount gets passed into renege as a negative number, but if a remainder is returned it will be positive
            amount = customer.renege(None, amount as i64, Some(&prices), right_now)? as i64;
            amt -= amount as u64; // < amt is used to keep track of how much we know (so far) that we'll be transferring 
        } 
        // whether we entered exposure's if clause or not (amount gets reused in there)...
        if amount.abs() > 0 { // if there's a remainder (returned by renege), or otherwise:            
            time_delta = right_now - customer.last_updated;
            customer.deposit_seconds += (time_delta as u64 * 
             customer.deposited_usd_star) as u128;

            let max_value = customer.deposit_seconds.saturating_mul(Banks.total_deposits as u128)
                    .checked_div(Banks.total_deposit_seconds).unwrap_or(0).min(u64::MAX as u128)  as u64;

            let value = max_value.min(amount.abs() as u64); 
        
            amt += value;
            Banks.total_deposits -= value;
            customer.deposited_usd_star -= customer.deposited_usd_star.min(value);
        }
        token_interface::transfer_checked(cpi_ctx, amt, decimals)?;
    } else { // < ticker was not ""
        let t: &str = ticker.as_str();
        if !exposure { // < withdraw pledged from specific ticker
            require!(amount < 0, PithyQuip::InvalidAmount);
            customer.renege(Some(t), amount, None, right_now)?;
            token_interface::transfer_checked(cpi_ctx, -amount as u64, decimals)?;
        } else { // amount positive for taking on long exposure, or short TP; negative for 
            // taking on short exposure, or TP for ^^^^^^^^^^^^
            let key: &str = ACCOUNT_MAP.get(t).ok_or(PithyQuip::UnknownSymbol)?;
            let hex: &str = HEX_MAP.get(t).ok_or(PithyQuip::UnknownSymbol)?;
            let first: &AccountInfo = &ctx.remaining_accounts[0];
            let first_key = first.key.to_string(); // `AccountInfo` has the `.key` field for the public key
            if first_key != key {
                return Err(PithyQuip::UnknownSymbol.into());
            }
            let mut first_data: &[u8] = &first.try_borrow_data()?;
            let price_update = PriceUpdateV2::try_deserialize(&mut first_data)?;
            
            let feed_id = get_feed_id_from_hex(hex)?;
            let price = price_update.get_price_no_older_than(&Clock::get()?, MAX_AGE, &feed_id)?;
            let adjusted_price = (price.price as f64) * 10f64.powi(price.exponent as i32);     

            let (mut delta, mut interest) = customer.repo(t,
                 amount, adjusted_price as u64, right_now, Banks.interest_rate)?;
            // ^ call this through external try catch, catch an error, passthrough,
            // try to borrow dollars against dollars on solend, passthrough again
            // if succeed, which calls the external try catch again if zero delta? 
            if delta != 0 { 
                if delta < 0 { // TP
                    delta *= -1; // < remove symbolic meaning, converting it to a usable number...
                    // interest includes (partially) the pod.pledged (delta is from total_deposits)
                    token_interface::transfer_checked(cpi_ctx, interest as u64, decimals)?;
                    interest = 0; // < so we don't add it back to the total_deposits later
                } else { // was auto-protected against liquidation
                    time_delta = right_now - customer.last_updated;
                    customer.deposit_seconds += (time_delta as u64 * 
                       (customer.deposited_usd_star + delta as u64)) as u128;
                    
                    customer.last_updated = right_now;
                }   
                Banks.total_deposits -= delta as u64;
            }   
            Banks.total_deposits += interest;
        }   
    } Ok(())    
}
