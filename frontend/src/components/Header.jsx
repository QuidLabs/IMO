import { Icon } from "./Icon"
import { useEffect, useState, useCallback } from "react"
import { shortedHash } from "../utils/shorted-hash"
import { numberWithCommas } from "../utils/number-with-commas"
import { useAppContext } from "../contexts/AppContext"
import "./Styles/Header.scss"

export const Header = () => {
  const {
    connectToMetaMask, getTotalInfo, getSdai, getSdaiBalance, getUserInfo, 
    account, connected
  } = useAppContext()

  const [actualAmount, setAmount] = useState(0)
  const [actualUsd, setUsd] = useState(0)
  const [actualSdai, setSdai] = useState(0)

  const handleConnectClick = useCallback(async () => {
    try {
      await connectToMetaMask()
    } catch (error) {
      console.error("Failed to connect to MetaMask", error)
    }
  }, [connectToMetaMask])

  const updatedTotalInfo = useCallback(async () => {
    try {
      await Promise.all([getTotalInfo(), getSdaiBalance()])
      .then( info => {
        if(info[0]){
          setUsd(info[0].total_dep)
          setAmount(info[0].total_mint)

          setSdai(info[1])
        }
      })
    } catch (error) {
      console.warn(`Failed to get total info:`, error)
    }
  }, [getTotalInfo, getSdaiBalance])


  const sdaiToWallet = useCallback(async () => {
    try {
      if (connected) await Promise.all([getSdai()]).then(() => updatedTotalInfo())
    } catch (error) {
      console.warn(`Failed to getting sdai on wallet:`, error)
    }    
  }, [getSdai, updatedTotalInfo, connected])

  useEffect(() => {
    if (connected) {
      connectToMetaMask()
      updatedTotalInfo()
    } else {
      getUserInfo()
    }
  }, [connected, connectToMetaMask, updatedTotalInfo, getUserInfo])

  const summary = (
    <div className="header-summary">
      <div className="header-summaryEl">
        <div className="header-summaryElTitle">Deposited</div>
        <div className="header-summaryElValue">
          ${numberWithCommas(actualUsd)}
        </div>
      </div>
      <div className="header-summaryEl">
        <div className="header-summaryElTitle">Minted QD</div>
        <div className="header-summaryElValue">
          {numberWithCommas(actualAmount)}
        </div>
      </div>
    </div>
  )

  const balanceBlock = (
    <div className="header-summaryEl">
      <div className="header-summaryElTitle">sDAI balance</div>
      <div className="header-summaryElValue">
        {numberWithCommas(parseFloat(actualSdai))}
      </div>
    </div>
  )

  return (
    <header className="header-root">
      <div className="header-logoContainer">
        <a className="header-logo" href="/"> </a>
      </div>
      {connected && account ? summary : null}
      <div className="header-walletContainer">
        {connected && account ? balanceBlock : null}
        {connected ? (
          <div className="header-wallet">
            <button className="header-wallet" onClick={() => sdaiToWallet()}>
              GET SDAI
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
          </div>
        ) : (
          <button className="header-wallet" onClick={handleConnectClick}>
            Connect Metamask
            <Icon name="btn-bg" className="header-walletBackground" />
          </button>
        )}
      </div>
    </header>
  )
}
