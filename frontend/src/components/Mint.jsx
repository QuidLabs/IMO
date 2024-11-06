import { useCallback, useEffect, useState, useRef } from "react"
import { formatUnits, parseUnits } from "@ethersproject/units"

import { Modal } from "./Modal"
import { Icon } from "./Icon"

import { useDebounce } from "../utils/use-debounce"
import { numberWithCommas } from "../utils/number-with-commas"

import { Buttons } from "./Adds/Buttons"

import { useAppContext } from "../contexts/AppContext"

import "./Styles/Mint.scss"

export const Mint = () => {
  const DELAY = 60 * 60 * 8

  const { getTotalSupply, setStorage, getWalletBalance,
    addressQD, addressSDAI, account, connected, chooseButton, swipeStatus, currentPrice, notifications, quid, sdai, mo } = useAppContext()

  const [mintValue, setMintValue] = useState("")
  const [sdaiValue, setSdaiValue] = useState(0)
  const [totalSupplyCap, setTotalSupplyCap] = useState(0)
  const [isSameBeneficiary, setIsSameBeneficiary] = useState(true)
  const [beneficiary, setBeneficiary] = useState("")
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [startMsg, setStartMsg] = useState('')

  const [insureStatus, setInsureStatus] = useState(true)

  const [buttonSign, setSign] = useState('')

  const [isProcessing, setIsProcessing] = useState(false)

  const buttonRef = useRef(null)
  const inputRef = useRef(null)
  const consoleRef = useRef(null)

  const handleCloseModal = () => setIsModalOpen(false)

  const calculatePrice = useCallback((num) => {
    try {
      return Number(num.toFixed(2)).toString()
    } catch (error) {
      console.error(error)
    }
  }, [])

  const handleAgreeTerms = useCallback(async () => {
    setIsModalOpen(false)
    localStorage.setItem("hasAgreedToTerms", "true")
    buttonRef.current?.click()
  }, [])

  const qdAmountToSdaiAmt = useCallback(async (qdAmount, delay = 0) => {
    const qdAmountBN = qdAmount ? qdAmount.toString() : 0

    return quid ? await quid.methods.qd_amt_to_dollar_amt(qdAmountBN).call() : 0
  },[quid])

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

  const handleChangeValue = (e) => {
    const regex = /^\d*(\.\d*)?$|^$/

    let originalValue = e.target.value

    if (originalValue.length > 1 && originalValue[0] === "0" && originalValue[1] !== ".")
      originalValue = originalValue.substring(1)

    if (originalValue[0] === ".") originalValue = "0" + originalValue

    if (regex.test(originalValue) && chooseButton === "MINT") setMintValue(Number(originalValue).toFixed())
      else if (regex.test(originalValue)) setMintValue(originalValue)
  }

  const setNotifications = useCallback((severity, message, status = false) => {
    setStorage(prevNotifications => [
      ...prevNotifications,
      { severity: severity, message: message, status: status }
    ])
  }, [setStorage])

  const handleEthSubmit = async () => {
    //const depInfo = await getDepositInfo()
    //  .then((numbers) => {
    //    return numbers
    //  })

    const beneficiaryAccount = !isSameBeneficiary && beneficiary !== "" ? beneficiary : account
    const hasAgreedToTerms = localStorage.getItem("hasAgreedToTerms") === "true"

    if (!hasAgreedToTerms) return setIsModalOpen(true)

    if (!isSameBeneficiary && beneficiary === "") return setNotifications("error", "Please select a beneficiary", false)

    if (!account) return setNotifications("error", "Please connect your wallet")

    if (!mintValue.length) return setNotifications("error", "Please enter the Etherum ballance")

    //if (mintValue < depInfo.weth_eth_balance + depInfo.work_eth_balance) return setNotifications("error", "The amount should be more than bla-bla-bla")

    const ballanceStatus = await getWalletBalance().then((balance) => {
      if (Number(mintValue) > Number(balance.eth)) return true
      else return false
    })

    if (ballanceStatus) return setNotifications("error", "Cost shouldn't be more than your Etherum balance")

    try {
      const ethDepo = parseUnits(mintValue, 18)
      setIsProcessing(true)
      setNotifications("info", "Processing. Please don't close or refresh page when terminal is working")
      setMintValue("")

      if (account) {
        await mo.methods.deposit(
          beneficiaryAccount.toString(),
          0, !insureStatus).send({ from: account, value: ethDepo.toString() })
      }

      setNotifications("success", "Your deposite has been pending completed!", true)

    } catch (err) {
      const er = "MO::mint: supply cap exceeded"
      const msg = err.error?.message === er || err.message === er ? "Please wait for more QD to become mintable..." : err.error?.message || err.message

      setNotifications("error", msg)
    } finally {
      setIsProcessing(false)
      setMintValue("")
    }
  }

  const handleSdaiSubmit = async () => {
    const beneficiaryAccount = !isSameBeneficiary && beneficiary !== "" ? beneficiary : account
    const hasAgreedToTerms = localStorage.getItem("hasAgreedToTerms") === "true"

    if (!hasAgreedToTerms) return setIsModalOpen(true)

    if (!isSameBeneficiary && beneficiary === "") return setNotifications("error", "Please select a beneficiary", false)

    if (!account) return setNotifications("error", "Please connect your wallet")

    if (!mintValue.length) return setNotifications("error", "Please enter amount")

    if (mintValue < 50) return setNotifications("error", "The amount should be more than 50")

    if (mintValue > totalSupplyCap) return setNotifications("error", "The amount should be less than the maximum mintable QD")

    const balance = async () => {
      if (sdai) return Number(formatUnits(await sdai.methods.balanceOf(account).call(), 18))
    }

    if (sdaiValue > (await balance())) return setNotifications("error", "Cost shouldn't be more than your sDAI balance")

    try {
      const qdAmount = parseUnits(mintValue, 18)
      setIsProcessing(true)
      setNotifications("info", "Processing. Please don't close or refresh page when terminal is working")
      setMintValue("")

      const sdaiAmount = await qdAmountToSdaiAmt(qdAmount, DELAY)
      const sdaiString = sdaiAmount ? sdaiAmount.toString() : 0

      const allowanceBigNumber = await sdai.methods.allowance(account, addressQD).call()
      const allowanceBigNumberBN = allowanceBigNumber ? allowanceBigNumber.toString() : 0

      setNotifications("info", `Start minting:\nCurrent allowance: ${formatUnits(allowanceBigNumberBN, 18)}\nNote amount: ${formatUnits(sdaiString, 18)}`)

      setNotifications("info", "Please, approve minting in your wallet.")

      if (account) await sdai.methods.approve(addressQD.toString(), sdaiAmount.toString()).send({ from: account })

      setNotifications("info", `Start minting:\nCurrent allowance: ${formatUnits(allowanceBigNumberBN, 18)}\nNote amount: ${formatUnits(sdaiString, 18)}`)

      setNotifications("success", "Please wait for approving")

      setNotifications("info", "Minting...")

      setNotifications("success", "Please check your wallet")

      const allowanceBeforeMinting = await sdai.methods.allowance(account, addressQD).call()

      setNotifications("info", `Start minting:\nQD amount: ${mintValue}\nCurrent account: ${account}\nAllowance: ${formatUnits(allowanceBeforeMinting, 18)}`)

      if (account) { await quid.methods.mint(
        beneficiaryAccount.toString(),
        qdAmount.toString(),
        addressSDAI.toString(), false).send({ from: account })
      }
      setNotifications("success", "Your minting is pending!", true)

    } catch (err) {
      const er = "MO::mint: supply cap exceeded"
      const msg = err.error?.message === er || err.message === er ? "Please wait for more QD to become mintable..." : err.error?.message || err.message

      setNotifications("error", msg)
    } finally {
      setIsProcessing(false)
      setMintValue("")
    }
  }

  const handleSubmit = () => {
    if (chooseButton.current === "MINT") handleSdaiSubmit()
    if (chooseButton.current === "DEPOSITE") handleEthSubmit()
  }

  const handleSetMaxValue = async () => {
    if (inputRef.current > totalSupplyCap) setMintValue(totalSupplyCap)
    else inputRef.current.focus()
  }

  const handleInsure = useCallback(() => {
    if(insureStatus) setInsureStatus(false)
    else setInsureStatus(true)
  },[insureStatus])

  useEffect(() => {
    if (quid) updateTotalSupply()

    if (consoleRef.current) consoleRef.current.scrollTop = consoleRef.current.scrollHeight

    if (account && connected && quid) setStartMsg('Terminal started. Mint is available!')
    else localStorage.setItem("consoleNotifications", JSON.stringify(''))

    if (notifications[0] && !connected) setTimeout(() => setStorage([]), 500)

  }, [updateTotalSupply, setStorage, account, connected, quid, notifications, isProcessing, sdaiValue])

  useEffect(() => {
    if (chooseButton.current === "MINT" || chooseButton.current == null) setSign('QD')
    else setSign('Ξ')
  }, [chooseButton, swipeStatus])

  return (
    <div className="mint">
      <div className="mint-root" onSubmit={handleSubmit}>
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
          <div className="mint-dollarSign">
            <button className="mint-dollarSign" id="mint-button">
              {buttonSign}
            </button>
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
          <label className="checkbox-container">
            {chooseButton.current === "MINT" || chooseButton.current == null ? null :
              <>
                <input
                  className="mint-checkBox"
                  type="checkbox"
                  checked={insureStatus}
                  onChange={() => handleInsure()}
                />
                <span className="mint-availabilityMax">INSURING</span>
              </>
            }
            <input
              name="isBeneficiary"
              className="mint-checkBox"
              type="checkbox"
              checked={isSameBeneficiary}
              onChange={() => setIsSameBeneficiary(!isSameBeneficiary)}
            />
            <span className="mint-availabilityMax">to myself</span>
          </label>
        </div>
        <Buttons
          names={["WITHDRAW", "MINT", "DEPOSITE"]}
          initialSlide={1}
          buttonRef={buttonRef}
          isProcessing={isProcessing}
          handleSubmit={handleSubmit}
        />
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
      </div>
      <div className="mint-console" ref={consoleRef}>
        <div className="mint-console-content">
          {connected ? startMsg : "Connect your MetaMask..."}
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
  )
}
