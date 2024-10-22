import { Icon } from "./Icon"
import { useEffect, useState, useCallback } from "react"
import { shortedHash } from "../utils/shorted-hash"
import { numberWithCommas } from "../utils/number-with-commas"
import { useAppContext } from "../contexts/AppContext"
import "./Styles/Header.scss"

export const Header = () => {
  const {
    connectToMetaMask, getTotalInfo, getUserInfo, getSdai,
    account, connected, UsdBalance
  } = useAppContext()

  const [actualAmount, setAmount] = useState(0)
  const [actualUsd, setUsd] = useState(0)

  const [grain, setGrain] = useState(0)

  const handleConnectClick = useCallback(async () => {
    try {
      await connectToMetaMask()
    } catch (error) {
      console.error("Failed to connect to MetaMask", error)
    }
  }, [connectToMetaMask])

  const updatedTotalInfo = useCallback(async () => {
    try {
      const updatedInfo = await getTotalInfo()

      if (updatedInfo && updatedInfo.total_dep && updatedInfo.total_mint) {
        const costInUsd = updatedInfo.total_dep
        const qdAmount = updatedInfo.total_mint

        setUsd(costInUsd)
        setAmount(qdAmount)

        setGrain(costInUsd !== 0 ? (qdAmount - UsdBalance).toFixed(2) : 0)
      }
    } catch (error) {
      console.warn(`Failed to get user info:`, error)
    }
  }, [getTotalInfo, UsdBalance])

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
        <div className="header-summaryElTitle">My Future QD</div>
        <div className="header-summaryElValue">
          {numberWithCommas(actualAmount)}
        </div>
      </div>
      <div className="header-summaryEl">
        <div className="header-summaryElTitle">Gain</div>
        <div className="header-summaryElValue">
          {numberWithCommas(grain)}
        </div>
      </div>
    </div>
  )

  const balanceBlock = (
    <div className="header-summaryEl">
      <div className="header-summaryElTitle">sDAI balance</div>
      <div className="header-summaryElValue">
        ${numberWithCommas(parseFloat(actualUsd))}
      </div>
    </div>
  )

  return (
    <header className="header-root">
      <div className="header-logoContainer">
        <a className="header-logo" href="/"> </a>
      </div>
      {connected ? summary : null}
      <div className="header-walletContainer">
        {connected ? balanceBlock : null}
        {connected ? (
          <div className="header-wallet">
            <button className="header-wallet" onClick={() => getSdai()}>
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
