import { useCallback, useEffect, useState, useRef } from "react"
import { formatUnits, parseUnits } from "@ethersproject/units"

import { Modal } from "./Modal"
import { Icon } from "./Icon"

import { useDebounce } from "../utils/use-debounce"
import { numberWithCommas } from "../utils/number-with-commas"

import { useAppContext } from "../contexts/AppContext"

import "./Styles/Mint.scss"

export const Mint = () => {
  const DELAY = 60 * 60 * 8

  const { 
    getTotalInfo, getUserInfo, getTotalSupply, 
    addressQD, addressUSDE, account, connected, currentPrice, quid, usde, addressMO, mo} = useAppContext()

  const [mintValue, setMintValue] = useState("")
  const [usdeValue, setUsdeValue] = useState(0)
  const [totalSupplyCap, setTotalSupplyCap] = useState(0)
  const [state, setState] = useState("MINT")
  const [isSameBeneficiary, setIsSameBeneficiary] = useState(true)
  const [beneficiary, setBeneficiary] = useState("")
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [notifications, setNotifications] = useState([])
  const [isProcessing, setIsProcessing] = useState(false)
  const [startMsg, setStartMsg] = useState('')

  const inputRef = useRef(null)
  const buttonRef = useRef(null)
  const consoleRef = useRef(null)

  const handleCloseModal = () => setIsModalOpen(false)

  const handleAgreeTerms = async () => {
    setIsModalOpen(false)
    localStorage.setItem("hasAgreedToTerms", "true")
    buttonRef.current?.click()
  }

  const qdAmountToUsdeAmt = async (qdAmount, delay = 0) => {
    const currentTimestamp = (Date.now() / 1000 + delay).toFixed(0)
    const currentTimestampBN = currentTimestamp.toString()
    const qdAmountBN = qdAmount ? qdAmount.toString() : 0

    return quid ? await quid.methods.qd_amt_to_dollar_amt(qdAmountBN, currentTimestampBN).call() : 0
  }

  useDebounce(
    mintValue,
    async () => {
      if (parseInt(mintValue) > 0) setUsdeValue(currentPrice * 0.01)
      else setUsdeValue(0)
    },
    500
  )

  const updateTotalSupply = useCallback(async () => {
    try {
      if (quid) {
        const totalSupply = await getTotalSupply()
        setTotalSupplyCap(totalSupply)
      }
    } catch (error) {
      console.error(error)
    }
  }, [getTotalSupply, quid])

  useEffect(() => {
    const local = localStorage.getItem("consoleNotifications")

    if(!notifications && local){
      const not =JSON.parse(local)
      
      setNotifications(not)
    } 

    if (quid) updateTotalSupply()

    if (consoleRef.current) consoleRef.current.scrollTop = consoleRef.current.scrollHeight

    if (account && connected && quid) {
      localStorage.setItem("consoleNotifications", JSON.stringify(notifications))
      setStartMsg('Terminal started. Mint is available!')
    } else localStorage.setItem("consoleNotifications", JSON.stringify(''))
  
    if(notifications[0] && !connected) setTimeout(() => setNotifications([]), 1000)

  }, [updateTotalSupply, account, connected, quid, notifications, isProcessing])

  const handleChangeValue = (e) => {
    const regex = /^\d*(\.\d*)?$|^$/

    let originalValue = e.target.value

    if (originalValue.length > 1 && originalValue[0] === "0" && originalValue[1] !== ".")
      originalValue = originalValue.substring(1)

    if (originalValue[0] === ".") originalValue = "0" + originalValue

    if (regex.test(originalValue)) setMintValue(Number(originalValue).toFixed(0))
  }

  const handleSubmit = async (e) => {
    if (e) e.preventDefault()

    const beneficiaryAccount = !isSameBeneficiary && beneficiary !== "" ? beneficiary : account
    const hasAgreedToTerms = localStorage.getItem("hasAgreedToTerms") === "true"

    if (!hasAgreedToTerms) {
      setIsModalOpen(true)
      return
    }

    if (!isSameBeneficiary && beneficiary === "") {
      setNotifications(prevNotifications => [
        ...prevNotifications,
        { severity: "error", message: "Please select a beneficiary" }
      ])
      return
    }

    if (!account) {
      setNotifications(prevNotifications => [
        ...prevNotifications,
        { severity: "error", message: "Please connect your wallet" }
      ])
      return
    }

    if (!mintValue.length) {
      setNotifications(prevNotifications => [
        ...prevNotifications,
        { severity: "error", message: "Please enter amount" }
      ])
      return
    }

    if (+mintValue < 50) {
      setNotifications(prevNotifications => [
        ...prevNotifications,
        { severity: "error", message: "The amount should be more than 50" }
      ])
      return
    }

    if (+mintValue > totalSupplyCap) {
      setNotifications(prevNotifications => [
        ...prevNotifications,
        { severity: "error", message: "The amount should be less than the maximum mintable QD" }
      ])
      return
    }

    const balance = async () => {
      if (usde) return Number(formatUnits(await usde.methods.balanceOf(account).call(), 18))
    }

    if (+usdeValue > (await balance())) {
      setNotifications(prevNotifications => [
        ...prevNotifications,
        { severity: "error", message: "Cost shouldn't be more than your sDAI balance" }
      ])
      return
    }

    try {
      const qdAmount = parseUnits(mintValue, 18)
      setIsProcessing(true)
      setState("Processing. Please don't close or refresh page when terminal is working")
      setMintValue("")

      const usdeAmount = await qdAmountToUsdeAmt(qdAmount, DELAY)
      const usdeString = usdeAmount ? usdeAmount.toString() : 0

      const allowanceBigNumber = await usde.methods.allowance(account, addressQD).call()
      const allowanceBigNumberBN = allowanceBigNumber ? allowanceBigNumber.toString() : 0
      const address = addressMO ? addressMO.toString() : 0

      setNotifications(prevNotifications => [
        ...prevNotifications,
        { severity: "info", message: `Start minting:\nCurrent allowance: ${formatUnits(allowanceBigNumberBN, 18)}\nNote amount: ${formatUnits(usdeString, 18)}` }
      ])

      if (parseInt(formatUnits(allowanceBigNumberBN, 18)) !== 0) {
        setState("decreaseAllowance")
        await usde.methods.decreaseAllowance(address, allowanceBigNumberBN).send({ from: account })
      }

      setState("approving")

      // TODO approve the QD erc20 not Moulinette

      if (account) await usde.methods.approve(addressQD.toString(), usdeAmount.toString()).send({ from: account })

      setNotifications(prevNotifications => [
        ...prevNotifications,
        { severity: "success", message: "Please wait for approving" }
      ])

      setState("minting")

      setNotifications(prevNotifications => [
        ...prevNotifications,
        { severity: "success", message: "Please check your wallet" }
      ])

      const allowanceBeforeMinting = await usde.methods.allowance(account, addressQD).call()

      setNotifications(prevNotifications => [
        ...prevNotifications,
        { severity: "info", message: `Start minting:\nQD amount: ${mintValue}\nCurrent account: ${account}\nAllowance: ${formatUnits(allowanceBeforeMinting, 18)}` }
      ])

      if (account) await mo.methods.deposit(
        beneficiaryAccount.toString(),
        qdAmount.toString(),
        addressUSDE.toString()).send({ from: account }
        )

      await getTotalInfo()
      await getUserInfo()

      setNotifications(prevNotifications => [
        ...prevNotifications,
        { severity: "success", message: "Your minting is pending!" }
      ])
    } catch (err) {
      const er = "MO::mint: supply cap exceeded"
      const msg = err.error?.message === er || err.message === er ? "Please wait for more QD to become mintable..." : err.error?.message || err.message

      setNotifications(prevNotifications => [
        ...prevNotifications,
        { severity: "error", message: msg }
      ])
    } finally {
      setIsProcessing(false)
      setState("none")
      setMintValue("")
    }
  }

  const handleSetMaxValue = async () => {
    if (totalSupplyCap) setMintValue(totalSupplyCap)
    if (inputRef.current) inputRef.current.focus()
  }

  return (
    <>
      <div className="mint">
        <form className="mint-root" onSubmit={handleSubmit}>
          <div className="mint-header">
            <span className="mint-title">
              <span className="mint-totalSupply">
                <span style={{ fontWeight: 400 , color: '#4ad300'}}>
                  {totalSupplyCap ? numberWithCommas(totalSupplyCap) : 0}
                  &nbsp;
                </span>
                QD mintable
              </span>
            </span>
          </div>
          <div className="mint-inputContainer">
            <input
              type="text"
              id="mint-input"
              className="mint-input"
              value={mintValue}
              onChange={handleChangeValue}
              placeholder="Mint amount"
              ref={inputRef}
            />
            <label htmlFor="mint-input" className="mint-dollarSign">
              QD
            </label>
            <button className="mint-maxButton" onClick={handleSetMaxValue} type="button">
              Max
              <Icon preserveAspectRatio="none" className="mint-maxButtonBackground" name="btn-bg" />
            </button>
          </div>
          <div className="mint-sub">
            <div className="mint-subLeft">
              Cost in $
              <strong>
                {usdeValue === 0 ? "sDAI Amount" : numberWithCommas(parseFloat(usdeValue))}
              </strong>
            </div>
            {mintValue ? (
              <div className="mint-subRight">
                <strong style={{ color: "#02d802" }}>
                  ${numberWithCommas((+mintValue - usdeValue).toFixed())}
                </strong>
                Future profit
              </div>
            ) : null}
          </div>
          <button ref={buttonRef} type="submit" className={isProcessing ? "mint-processing" : "mint-submit" }>
            {isProcessing ? "Processing" : state !== "none" ? `${state}` : "MINT"}
            <div className={isProcessing || !connected ? null : "mint-glowEffect"} />
          </button>
          <label style={{ position: "absolute", top: 165, right: -170 }}>
            <input
              name="isBeneficiary"
              className="mint-checkBox"
              type="checkbox"
              checked={isSameBeneficiary}
              onChange={() => setIsSameBeneficiary(!isSameBeneficiary)}
            />
            <span className="mint-availabilityMax">to myself</span>
          </label>
          {isSameBeneficiary ? null : (
            <div className="mint-beneficiaryContainer">
              <div className="mint-inputContainer">
                <input
                  name="beneficiary"
                  type="text"
                  className="mint-beneficiaryInput"
                  onChange={(e) => setBeneficiary(e.target.value)}
                  placeholder={account ? String(account) : ""}
                />
                <label htmlFor="mint-input" className="mint-idSign">
                  beneficiary
                </label>
              </div>
            </div>
          )}
          <Modal open={isModalOpen} handleAgree={handleAgreeTerms} handleClose={handleCloseModal} />
        </form>
        <div className="mint-console" ref={consoleRef}>
          <div className="mint-console-content">
            {notifications && connected ? startMsg : "Connect your MetaMask..."}
            {notifications ? notifications.map((notification, index) => (
              <div
                key={index}
                className={`mint-console-line ${notification.severity}`}
              >
                {notification.message}
              </div>
            )): null}
            {isProcessing && (
              <div className="mint-console-line info">
                Processing<span className="processing-dots">...</span>
              </div>
            )}
          </div>
        </div>
      </div>
    </>
  )
}
