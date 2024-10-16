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

  const { getTotalInfo, getUserInfo, getTotalSupply, changeButton, setStorage, getStorage,
    addressQD, addressSDAI, account, connected, currentPrice, notifications, quid, sdai } = useAppContext()

  const [mintValue, setMintValue] = useState("")
  const [sdaiValue, setSdaiValue] = useState(0)
  const [totalSupplyCap, setTotalSupplyCap] = useState(0)
  const [state, setState] = useState("MINT")
  const [isSameBeneficiary, setIsSameBeneficiary] = useState(true)
  const [beneficiary, setBeneficiary] = useState("")
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [isProcessing, setIsProcessing] = useState(false)
  const [startMsg, setStartMsg] = useState('')

  const [glowClass, setGlowClass] = useState('')

  const inputRef = useRef(null)
  const buttonRef = useRef(null)
  const consoleRef = useRef(null)

  const handleCloseModal = () => setIsModalOpen(false)

  const calculatePrice = useCallback((num) => {
    try {
      return Number(num.toFixed(2)).toString()
    } catch (error) {
      console.error(error)
    }
  }, [])

  const handleAgreeTerms = async () => {
    setIsModalOpen(false)
    localStorage.setItem("hasAgreedToTerms", "true")
    buttonRef.current?.click()
  }

  const qdAmountToSdaiAmt = async (qdAmount, delay = 0) => {
    const currentTimestamp = (Date.now() / 1000 + delay).toFixed(0)
    const currentTimestampBN = currentTimestamp.toString()
    const qdAmountBN = qdAmount ? qdAmount.toString() : 0

    return quid ? await quid.methods.qd_amt_to_dollar_amt(qdAmountBN, currentTimestampBN).call() : 0
  }

  useDebounce(
    mintValue,
    async () => {
      if (parseInt(mintValue) > 0) setSdaiValue(currentPrice * 0.01)
      else setSdaiValue(0)
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
    if (quid) updateTotalSupply()

    if (consoleRef.current) consoleRef.current.scrollTop = consoleRef.current.scrollHeight

    if (account && connected && quid) {
      getStorage()
      setStartMsg('Terminal started. Mint is available!')

      const classState = changeButton(isProcessing, true)

      setGlowClass(classState)
    } else localStorage.setItem("consoleNotifications", JSON.stringify(''))

    if (notifications[0] && !connected) setTimeout(() => {
      setStorage([])

      const classState = changeButton(isProcessing, false)

      setGlowClass(classState)
    }, 500)
  }, [updateTotalSupply, changeButton, getStorage, setStorage, account, connected, quid, notifications, isProcessing])

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
      setStorage(prevNotifications => [
        ...prevNotifications,
        { severity: "error", message: "Please select a beneficiary" }
      ])
      return
    }

    if (!account) {
      setStorage(prevNotifications => [
        ...prevNotifications,
        { severity: "error", message: "Please connect your wallet" }
      ])
      return
    }

    if (!mintValue.length) {
      setStorage(prevNotifications => [
        ...prevNotifications,
        { severity: "error", message: "Please enter amount" }
      ])
      return
    }

    if (+mintValue < 50) {
      setStorage(prevNotifications => [
        ...prevNotifications,
        { severity: "error", message: "The amount should be more than 50" }
      ])
      return
    }

    if (+mintValue > totalSupplyCap) {
      setStorage(prevNotifications => [
        ...prevNotifications,
        { severity: "error", message: "The amount should be less than the maximum mintable QD" }
      ])
      return
    }

    const balance = async () => {
      if (sdai) return Number(formatUnits(await sdai.methods.balanceOf(account).call(), 18))
    }

    if (+sdaiValue > (await balance())) {
      setStorage(prevNotifications => [
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

      const sdaiAmount = await qdAmountToSdaiAmt(qdAmount, DELAY)
      const sdaiString = sdaiAmount ? sdaiAmount.toString() : 0

      const allowanceBigNumber = await sdai.methods.allowance(account, addressQD).call()
      const allowanceBigNumberBN = allowanceBigNumber ? allowanceBigNumber.toString() : 0
      const addresQDBN = addressQD ? addressQD.toString() : 0

      setStorage(prevNotifications => [
        ...prevNotifications,
        { severity: "info", message: `Start minting:\nCurrent allowance: ${formatUnits(allowanceBigNumberBN, 18)}\nNote amount: ${formatUnits(sdaiString, 18)}` }
      ])

      if (parseInt(formatUnits(allowanceBigNumberBN, 18)) !== 0) {
        setState("decreaseAllowance")
        await sdai.methods.decreaseAllowance(addresQDBN, allowanceBigNumberBN).send({ from: account })
      }

      setState("approving")

      if (account) await sdai.methods.approve(addressQD.toString(), sdaiAmount.toString()).send({ from: account })

      setStorage(prevNotifications => [
        ...prevNotifications,
        { severity: "success", message: "Please wait for approving" }
      ])

      setState("minting")

      setStorage(prevNotifications => [
        ...prevNotifications,
        { severity: "success", message: "Please check your wallet" }
      ])

      const allowanceBeforeMinting = await sdai.methods.allowance(account, addressQD).call()

      setStorage(prevNotifications => [
        ...prevNotifications,
        { severity: "info", message: `Start minting:\nQD amount: ${mintValue}\nCurrent account: ${account}\nAllowance: ${formatUnits(allowanceBeforeMinting, 18)}` }
      ])

      if (account) await quid.methods.deposit(
        beneficiaryAccount.toString(),
        qdAmount.toString(),
        addressSDAI.toString()).send({ from: account }
        )

      await getTotalInfo()
      await getUserInfo()

      setStorage(prevNotifications => [
        ...prevNotifications,
        { severity: "success", message: "Your minting is pending!" }
      ])
    } catch (err) {
      const er = "MO::mint: supply cap exceeded"
      const msg = err.error?.message === er || err.message === er ? "Please wait for more QD to become mintable..." : err.error?.message || err.message

      setStorage(prevNotifications => [
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
    if (inputRef.current > totalSupplyCap) setMintValue(totalSupplyCap)
    else inputRef.current.focus()
  }

  return (
    <>
      <div className="mint">
        <form className="mint-root" onSubmit={handleSubmit}>
          <div className="mint-header">
            <span className="mint-title">
              <span className="mint-totalSupply">
                <span style={{ fontWeight: 400, color: '#4ad300' }}>
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
            <button className="mint-dollarSign" id="mint-button">
              QD
            </button>
            <div className="mint-links">
              <button href="#" className="mint-link">Link 1</button>
              <button href="#" className="mint-link">Link 2</button>
            </div>
            <button className="mint-maxButton" onClick={handleSetMaxValue} type="button">
              Max
              <Icon preserveAspectRatio="none" className="mint-maxButtonBackground" name="btn-bg" />
            </button>
          </div>
          <div className="mint-sub">
            <div className="mint-subLeft">
              Cost in $
              <strong>
                {sdaiValue === 0 ? "sDAI Amount" : numberWithCommas(calculatePrice(sdaiValue * mintValue))}
              </strong>
            </div>
            {mintValue ? (
              <div className="mint-subRight">
                <strong style={{ color: "#02d802" }}>
                  ${numberWithCommas((+mintValue - sdaiValue).toFixed())}
                </strong>
                Future profit
              </div>
            ) : null}
          </div>
          <button ref={buttonRef} type="submit" className={isProcessing ? "mint-processing" : "mint-submit"}>
            {isProcessing ? "Processing" : state !== "none" ? `${state}` : "MINT"}
            <div className={`mint-glowEffect mint-glow-${glowClass}`} />
          </button>
          <button type="button" className="dd-submit">
            DROP DOWN
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
            )) : null}
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
