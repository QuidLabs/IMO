import { useCallback, useEffect, useState } from "react"
import { useAppContext } from "../contexts/AppContext";
import { numberWithCommas } from "../utils/number-with-commas"

import "./Styles/Summary.scss"

export const Summary = () => {
  const { getSales, getUserInfo, setAllInfo, changeButton,
    connected, currentTimestamp, quid, sdai, addressQD, SECONDS_IN_DAY } = useAppContext();

  const [smartContractStartTimestamp, setSmartContractStartTimestamp] = useState("")
  const [mintPeriodDays, setMintPeriodDays] = useState("")

  const [days, setDays] = useState("")
  const [totalDeposited, setTotalDeposited] = useState("")
  const [totalMinted, setTotalMinted] = useState("")
  const [price, setPrice] = useState("")

  const [glowClass, setGlowClass] = useState('')

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
      if (connected && quid && sdai && addressQD) {
        await Promise.all([getUserInfo(), getSales(), calculateDays()])
          .then(array => {

            setTotalDeposited(array[0].actualUsd)
            setTotalMinted(array[0].actualQD)
            setPrice(array[0].price)
            
            setMintPeriodDays(array[1].mintPeriodDays)
            setSmartContractStartTimestamp(array[1].smartContractStartTimestamp)

            setDays(array[2].days)

            console.log('actualDays', array[2].days)
          })
      } else {
        setAllInfo(0, 0, 0, 0, 0, true)
      }
    } catch (error) {
      console.error("Some problem with updateInfo, Summary.js, l.22: ", error)
    }
  }, [calculateDays, getSales, getUserInfo, setAllInfo,
    addressQD, connected, sdai, quid])

  useEffect(() => {
    try {
      const classState = changeButton(false, true)

      setGlowClass(classState)

      updatingInfo()
    } catch (error) {
      console.error("Some problem with sale's start function: ", error)
    }
  }, [changeButton, updatingInfo])

  return (
    <div  className={`summary-root ${glowClass}`} >
      <div className="summary-section">
        <div className="summary-title">Days left</div>
        <div className="summary-value">{days ? days : "⋈"}</div>
      </div>
      <div className="summary-section">
        <div className="summary-title">Current price</div>
        <div className="summary-value">
          <span className="summary-value">{Number(price).toFixed(0)}</span>
          <span className="summary-cents"> Cents</span>
        </div>
      </div>
      <div className="summary-section">
        <div className="summary-title">sDAI Deposited</div>
        <div className="summary-value">
          ${numberWithCommas(parseFloat(String(Number(totalDeposited))).toFixed())}
        </div>
      </div>
      <div className="summary-section">
        <div className="summary-title">Minted QD</div>
        <div className="summary-value">
          {numberWithCommas(parseFloat(Number(totalMinted).toFixed(1)))}
        </div>
      </div>
    </div>
  )
}
