import { useCallback, useEffect, useState } from "react"
import { useAppContext } from "../contexts/AppContext";
import { numberWithCommas } from "../utils/number-with-commas"

import "./Styles/MintBar.scss"

export const MintBar = () => {
  const { getSales, getUserInfo, resetAccounts, setCurrentPrice,
    account, connected, currentTimestamp, quid, usde, notifications, addressQD, SECONDS_IN_DAY } = useAppContext()

  const [smartContractStartTimestamp, setSmartContractStartTimestamp] = useState("")
  const [mintPeriodDays, setMintPeriodDays] = useState("")

  const [days, setDays] = useState("")
  const [totalDeposited, setTotalDeposited] = useState("")
  const [totalMinted, setTotalMinted] = useState("")
  const [gain, setGain] = useState("")
  const [price, setPrice] = useState("")

  const calculateDays = useCallback(async () => {
    try {
      const actualDays = Number(mintPeriodDays) - (Number(currentTimestamp) - Number(smartContractStartTimestamp)) / SECONDS_IN_DAY
      const frmtdDays = Math.max(Math.ceil(actualDays), 0)

      return { days: frmtdDays }
    } catch (error) {
      console.error(error)
    }
  }, [mintPeriodDays, currentTimestamp, smartContractStartTimestamp, SECONDS_IN_DAY])

  const updatingInfo = useCallback(async () => {
    try {
      if (connected && account && quid && usde && addressQD) {
        await Promise.all([getUserInfo(), getSales(), calculateDays()])
          .then(values => {
            setTotalDeposited(values[0].actualUsd)
            setTotalMinted(values[0].actualQD)
            setPrice(values[0].price)
            setCurrentPrice(values[0].price)

            setMintPeriodDays(values[1].mintPeriodDays)
            setSmartContractStartTimestamp(values[1].smartContractStartTimestamp)

            setDays(values[2].days)

            setGain((values[0].actualQD - values[0].actualUsd).toFixed(2))
          })
      } else resetAccounts(true)
    } catch (error) {
      console.error("Some problem with updateInfo, Summary.js, l.22: ", error)
    }
  }, [calculateDays, getSales, getUserInfo, resetAccounts, setCurrentPrice,
    account, addressQD, connected, usde, quid])

  useEffect(() => {
    try {
      updatingInfo()
    } catch (error) {
      console.error("Some problem with sale's start function: ", error)
    }
  }, [resetAccounts, updatingInfo, connected, notifications])

  return (
    <div className={`summary-root`} >
      <div className="summary-section">
        <div className="summary-title">Days left</div>
        <div className="summary-value">{connected && days && account ? days : "⋈"}</div>
      </div>
      <div className="summary-section">
        <div className="summary-title">QD price</div>
        <div className="summary-value">
          <span className="summary-value">{connected && account ? numberWithCommas(parseFloat(Number(price).toFixed(0))) : 0}</span>
          <span className="summary-cents"> Cents</span>
        </div>
      </div>
      <div className="summary-section">
        <div className="summary-title">$ Deposited</div>
        <div className="summary-value">
          ${connected && account ? numberWithCommas(parseFloat(Number(totalDeposited).toFixed(0))) : 0}
        </div>
      </div>
      <div className="summary-section">
        <div className="summary-title">Gain in $</div>
        <div className="summary-value">
          {connected && account ? numberWithCommas(parseFloat(Number(gain).toFixed(0))) : 0}
        </div>
      </div>
      <div className="summary-section">
        <div className="summary-title">QD (future $)</div>
        <div className="summary-value">
          {connected && account ? numberWithCommas(parseFloat(Number(totalMinted).toFixed(0))) : 0}
        </div>
      </div>
    </div>
  )
}
