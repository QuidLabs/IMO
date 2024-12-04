import { Icon } from "./Icon"
import { useEffect, useState, useCallback } from "react"
import { shortedHash } from "../utils/shorted-hash"
import { numberWithCommas } from "../utils/number-with-commas"
import { useAppContext } from "../contexts/AppContext"

import "./Styles/Header.scss"

import { SepoliaChecker } from "./SepoliaChecker"

export const Header = () => {
  const {
    connectToMetaMask, getTotalInfo, getUsde, getWalletBalance, getUserInfo,
    account, connected, notifications
  } = useAppContext()

  const [actualAmount, setAmount] = useState(0)
  const [actualUsd, setUsd] = useState(0)
  const [actualUsde, setUsde] = useState(0)
  const [actualEth, setEth] = useState(0)

  const handleConnectClick = useCallback(async () => {
    try {
      await connectToMetaMask()
    } catch (error) {
      console.error("Failed to connect to MetaMask", error)
    }
  }, [connectToMetaMask])

  const updatedTotalInfo = useCallback(async () => {
    try {
      await Promise.all([getTotalInfo(), getWalletBalance()])
        .then(info => {
          if (info[0]) {
            setUsd(info[0].total_dep)
            setAmount(info[0].total_mint)

            setUsde(info[1].usde)
            setEth(info[1].eth)
          }
        })
    } catch (error) {
      console.warn(`Failed to get total info:`, error)
    }
  }, [getTotalInfo, getWalletBalance])


  const usdeToWallet = useCallback(async () => {
    try {
      if (connected) await Promise.all([getUsde()]).then(() => updatedTotalInfo())
    } catch (error) {
      console.warn(`Failed to getting usde on wallet:`, error)
    }
  }, [getUsde, updatedTotalInfo, connected])

  useEffect(() => {
    if (connected) {
      connectToMetaMask()
      updatedTotalInfo()
    } else {
      getUserInfo()
    }
  }, [connectToMetaMask, updatedTotalInfo, getUserInfo, connected, notifications])

  const summary = (
    <>
      <div className="header-summaryEl fade-in">
        <div className="header-summaryElTitle">Deposited</div>
        <div className="header-summaryElValue">
          ${numberWithCommas(Number(actualUsd).toFixed())}
        </div>
      </div>
      <div className="header-summaryEl fade-in">
        <div className="header-summaryElTitle">Minted QD</div>
        <div className="header-summaryElValue">
          {numberWithCommas(Number(actualAmount).toFixed())}
        </div>
      </div>
    </>
  )

  const balanceBlock = (
    <>
      <div className="header-summaryEl fade-in">
        <div className="header-summaryElTitle">ETH balance</div>
        <div className="header-summaryElValue">
          Ξ{Number(actualEth).toFixed(4)}
        </div>
      </div>
      <div className="header-summaryEl fade-in">
        <div className="header-summaryElTitle">USDe balance</div>
        <div className="header-summaryElValue">
          ${numberWithCommas(parseFloat(Number(actualUsde).toFixed(2)))}
        </div>
      </div>
    </>
  )

  return (
    <header className="header-root">
      <div className="header-logoContainer fade-in">
        <a className="header-logo" href="https://yo.quid.io"> </a>
      </div>
      <div className="header-summary fade-in">
        {connected && account ? summary : null}
        {connected && account ? balanceBlock : null}
      </div>
      <div className="header-walletContainer">
        {connected ? (
          <div className="header-wallet fade-in">
            <button className="header-wallet" onClick={() => usdeToWallet()}>
              Mint USDe
            </button>
            <div className="header-metamaskIcon">
              <img
                width="18"
                height="18"
                src="/images/metamask.svg"
                alt="metamask"
              />
            </div>
            {shortedHash(account)}
            <Icon name="btn-bg" className="header-walletBackground" />
            <SepoliaChecker />
          </div>          
        ) : (
          <button className="header-wallet fade-in" onClick={handleConnectClick}>
            Connect Metamask
            <Icon name="btn-bg" className="header-walletBackground" />
          </button>
        )}
      </div>
    </header>
  )
}
