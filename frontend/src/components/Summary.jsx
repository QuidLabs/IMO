
import { useEffect, useState, useCallback } from "react"
import { useAppContext } from "../contexts/AppContext";
import { numberWithCommas } from "../utils/number-with-commas"

import "./Styles/Summary.scss"

export const Summary = () => {
  const { getSales, getUserInfo, setAllInfo, changeButton,
    connected, currentTimestamp, quid, sdai, addressQD, SECONDS_IN_DAY } = useAppContext();

  const [smartContractStartTimestamp, setSmartContractStartTimestamp] = useState("")
  const [mintPeriodDays, setMintPeriodDays] = useState("")
  const [totalDeposited, setTotalDeposited] = useState("")
  const [totalMinted, setTotalMinted] = useState("")
  const [price, setPrice] = useState("")

  const [days, setDays] = useState("")

  const [glowClass, setGlowClass] = useState('')

  const calculateDays = useCallback(async () => {
    try {
      const actualDays = Number(mintPeriodDays) - (Number(currentTimestamp) - Number(smartContractStartTimestamp)) / SECONDS_IN_DAY
      const frmtdDays = Math.max(Math.ceil(actualDays), 0)

      return { left: frmtdDays }
    } catch (error) {
      console.error(error)
    }
  }, [mintPeriodDays, currentTimestamp, smartContractStartTimestamp, SECONDS_IN_DAY])

  const updatingInfo = useCallback(async () => {
    try {
      if (quid && sdai && addressQD) {
        const updatedInfo = await getUserInfo()
        const updatedSales = await getSales()

        const days = await calculateDays()

        if (updatedInfo) {
          setTotalDeposited(updatedInfo.actualUsd)
          setTotalMinted(updatedInfo.actualQD)
          setPrice(updatedInfo.price)

          setDays(days.left)
        }

        setMintPeriodDays(updatedSales.mintPeriodDays)
        setSmartContractStartTimestamp(updatedSales.smartContractStartTimestamp)


      }
    } catch (error) {
      console.error("Some problem with updateInfo, Summary.js, l.22: ", error)
    }
  }, [addressQD, sdai, quid, getSales, getUserInfo, calculateDays])

  useEffect(() => {
    try {
      if (connected) updatingInfo()
      else {
        setAllInfo(0, 0, 0, 0, 0, true)

        setTotalDeposited(0)
        setTotalMinted(0)
        setPrice(0)
        setDays("⋈")
      }

      const classState = changeButton(false, true)
      setGlowClass(classState)
    } catch (error) {
      console.error("Some problem with sale's start function: ", error)
    }
  }, [updatingInfo, setAllInfo, setGlowClass, changeButton, connected])

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
