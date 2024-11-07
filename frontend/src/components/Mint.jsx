import { useCallback, useEffect, useState, useRef } from "react"
import { formatUnits, parseUnits } from "@ethersproject/units"

import { Modal } from "./Modal"
import { Icon } from "./Icon"

import { numberWithCommas } from "../utils/number-with-commas"

import { Buttons } from "./Adds/Buttons"

import { useAppContext } from "../contexts/AppContext"

import "./Styles/Mint.scss"

export const Mint = () => {
  const DELAY = 60 * 60 * 8

  const { getTotalSupply, setStorage, getWalletBalance, getDepositInfo, getTotalInfo,
    addressQD, addressSDAI, account, connected, chooseButton, swipeStatus, currentPrice, notifications, quid, sdai, mo, addressMO } = useAppContext()

  const [mintValue, setMintValue] = useState('')
  const [sdaiValue, setSdaiValue] = useState('')
  const [totalSupplyCap, setTotalSupplyCap] = useState(0)
  const [isSameBeneficiary, setIsSameBeneficiary] = useState(true)
  const [beneficiary, setBeneficiary] = useState('')
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [startMsg, setStartMsg] = useState('')

  const [insureStatus, setInsureStatus] = useState(true)
  const [withdrawStatus, setWithdrawStatus] = useState(false)
  const [choiseCurrency, setCurrency] = useState('QUID')

  const [ethPrice, setETHPrice] = useState(0)

  const [insureble, setInsureble] = useState('')

  const [buttonSign, setSign] = useState('')
  const [placeHolder, setPlaceHolder] = useState('Mint amount')

  const [isProcessing, setIsProcessing] = useState(false)

  const buttonRef = useRef(null)
  const inputRef = useRef(null)
  const consoleRef = useRef(null)

  const handleCloseModal = () => setIsModalOpen(false)

  const handlePrice = useCallback(async (status) =>{
    try {
      await mo.methods.set_price_eth(status, false).send({ from:account })
      .then(async (value) => {
        const priceCall = await quid.methods.getPrice().call()
        .then((value) => {
          return parseFloat(value) / 1e18
        })
        console.log("Price changed to: ", priceCall, "INFO: ", value)
      })
    } catch (error) {
      console.error("Test's pricing error", error)
    }
  },[account, mo, quid])

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
  }, [quid])

  const updateTotalSupply = useCallback(async () => {
    try {
      if (quid) {
        await Promise.all([getTotalSupply(), getDepositInfo(addressMO), getTotalInfo()])
          .then((value) => {
            const deposite = value[2].total_dep
            const wethUsdBalance = value[1].weth_usd_balance
            const price = value[1].ethPrice

            setTotalSupplyCap(value[0])
            setInsureble(deposite - (wethUsdBalance * price))
            setETHPrice(price)
          })
      }
    } catch (error) {
      console.error(error)
    }
  }, [getDepositInfo, getTotalInfo, getTotalSupply, addressMO, quid])

  const handleChangeValue = useCallback((e) => {
    const regex = /^\d*(\.\d*)?$|^$/

    let originalValue = e.target.value

    if (originalValue.length > 1 && originalValue[0] === "0" && originalValue[1] !== ".")
      originalValue = originalValue.substring(1)

    if (originalValue[0] === ".") originalValue = "0" + originalValue

    if (regex.test(originalValue)) {
      if (chooseButton === "MINT") {
        setSdaiValue(currentPrice * 0.01)
        setMintValue(Number(originalValue).toFixed())
      }
      else {
        setMintValue(originalValue)
        setSdaiValue(currentPrice * 0.01)
      }
    }
  }, [chooseButton, currentPrice])

  const setNotifications = useCallback((severity, message, status = false) => {
    setStorage(prevNotifications => [
      ...prevNotifications,
      { severity: severity, message: message, status: status }
    ])
  }, [setStorage])

  const terminalStarting = async (button) => {
    const beneficiaryAccount = !isSameBeneficiary && beneficiary !== "" ? beneficiary : account
    const hasAgreedToTerms = localStorage.getItem("hasAgreedToTerms") === "true"

    if (!hasAgreedToTerms) return setIsModalOpen(true)

    if (!isSameBeneficiary && beneficiary === "") return setNotifications("error", "Please select a beneficiary", false)

    if (!account) return setNotifications("error", "Please connect your wallet")

    if (!mintValue.length) return setNotifications("error", "Please enter amount")

    const balance = async () => {
      if (sdai) return Number(formatUnits(await sdai.methods.balanceOf(account).call(), 18))
    }

    try {
      if (button === "MINT") {
        if (mintValue < 50) return setNotifications("error", "The amount should be more than 50")

        if (mintValue > totalSupplyCap) return setNotifications("error", "The amount should be less than the maximum mintable QD")

        if (sdaiValue > (await balance())) return setNotifications("error", "Cost shouldn't be more than your sDAI balance")

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

        if (account) {
          await quid.methods.mint(
            beneficiaryAccount.toString(),
            qdAmount.toString(),
            addressSDAI.toString(), false).send({ from: account })
        }
        setNotifications("success", "Your minting is pending!", true)
      }

      if (button === "DEPOSITE") {
        const depInfo = await getDepositInfo()
          .then((numbers) => {
            return numbers
        })

        if (mintValue > depInfo.weth_eth_balance + depInfo.work_eth_balance) return setNotifications("error", "The amount should be less than the insureble value.")

        const ballanceStatus = await getWalletBalance().then((balance) => {
          if (Number(mintValue) > Number(balance.eth)) return true
          else return false
        })

        if (ballanceStatus) return setNotifications("error", "Cost shouldn't be more than your Etherum balance")

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
      }

      if (button === "WITHDRAW") {
        const depInfo = await getDepositInfo()
          .then((numbers) => {
            return numbers
        })

        if (withdrawStatus && (mintValue > depInfo.weth_eth_balance + depInfo.work_eth_balance)) return setNotifications("error", "The withdraw amount should be less than the insureble value.")

        if (withdrawStatus && mintValue > depInfo.work_eth_balance){ 
          const foldValue = mintValue - depInfo.work_eth_balance

          mo.methods.fold(account, foldValue, false).send()
        }
        const ballanceStatus = await getWalletBalance().then((balance) => {
          if (Number(mintValue) > Number(balance.eth)) return true
          else return false
        })

        if (withdrawStatus && ballanceStatus) return setNotifications("error", "Cost shouldn't be more than your Etherum balance")

        const depositeBuffer = ethPrice * depInfo.work_eth_balance - depInfo.work_usd_balance

        if (!withdrawStatus && sdaiValue > depositeBuffer) return setNotifications("error", "Input amount shouldn't be more than insurable")

        const withDrawValue = parseUnits(mintValue, 18).toString()
        setIsProcessing(true)
        setNotifications("info", "Processing. Please don't close or refresh page when terminal is working")
        setMintValue("")

        if (account) {
          await mo.methods.withdraw(withDrawValue, !withdrawStatus).send({from: account})
          
          setNotifications("success", "The withdraw has been pending completed!", true)
        }
      }

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
    terminalStarting(chooseButton.current)
  }

  const handleSetMaxValue = async () => {
    if (inputRef.current > totalSupplyCap) setMintValue(totalSupplyCap)
    else inputRef.current.focus()
  }

  const handleInsure = useCallback(() => {
    if (insureStatus) setInsureStatus(false)
    else setInsureStatus(true)
  }, [insureStatus])


  const handleWithdraw = useCallback(() => {
    if (withdrawStatus) {
      setWithdrawStatus(false)
      setCurrency("QUID")
    }
    else {
      setWithdrawStatus(true)
      setCurrency("ETHERUM")
    }
  }, [withdrawStatus])

  useEffect(() => {
    if (quid) updateTotalSupply()

    if (consoleRef.current) consoleRef.current.scrollTop = consoleRef.current.scrollHeight

    if (account && connected && quid) setStartMsg('Terminal started. Mint is available!')
    else localStorage.setItem("consoleNotifications", JSON.stringify(''))

    if (notifications[0] && !connected) setTimeout(() => setStorage([]), 500)

  }, [updateTotalSupply, setStorage, account, connected, quid, notifications, isProcessing])

  useEffect(() => {
    if (chooseButton.current === "MINT" || chooseButton.current == null) {
      setSign('QD')
      setPlaceHolder('Mint amount')
    } else if (chooseButton.current === "DEPOSITE") {
      setSign('Ξ')
      setPlaceHolder('Deposite amount')
    } else if (chooseButton.current === "WITHDRAW" && !withdrawStatus) {
      setSign('QD')
      setPlaceHolder('Withdraw amount')
    } else {
      setSign('Ξ')
      setPlaceHolder('Withdraw amount')
    }
  }, [chooseButton, swipeStatus, withdrawStatus])

  return (
    <div className="mint">
      <div className="mint-root" onSubmit={handleSubmit}>
        <div className="mint-header">
          <span className="mint-title">
            <span className="mint-totalSupply">
              {chooseButton.current === "MINT" || chooseButton.current == null ?
                (
                  <>
                    <span style={{ fontWeight: 400, color: '#4ad300' }}>
                      {totalSupplyCap ? numberWithCommas(totalSupplyCap) : 0}
                      &nbsp;
                    </span>
                    QD mintable
                  </>
                ) : (
                  <>
                    <span style={{ fontWeight: 400, color: '#4ad300' }}>
                      {insureble ? numberWithCommas(Number(insureble).toFixed(0)) : 0}
                      &nbsp;
                    </span>
                    $ insurable
                  </>
                )}
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
            placeholder={placeHolder}
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
          {mintValue && (chooseButton.current === "MINT" || chooseButton.current == null) ? (
            <div className="mint-subRight">
              <strong style={{ color: "#02d802" }}>
                ${numberWithCommas((+mintValue - sdaiValue).toFixed())}
              </strong>
              Future profit
            </div>
          ) : null}
          <label className="checkbox-container">
            {chooseButton.current === "MINT" || chooseButton.current == null || chooseButton.current === "WITHDRAW" ? null :
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
            {chooseButton.current === "MINT" || chooseButton.current == null || chooseButton.current === "DEPOSITE" ?
              <>
                <input
                  name="isBeneficiary"
                  className="mint-checkBox"
                  type="checkbox"
                  checked={isSameBeneficiary}
                  onChange={() => setIsSameBeneficiary(!isSameBeneficiary)}
                />
                <span className="mint-availabilityMax">to myself</span>
              </> : null
            }
            {chooseButton.current === "WITHDRAW" ?
              <>
                <span className="mint-availabilityMax"><b style={{ color: '#4ad300' }}>{choiseCurrency}</b></span>
                <label className="switch">
                  <input
                    type="checkbox"
                    checked={withdrawStatus}
                    onChange={() => handleWithdraw()}
                  />
                  <span className="slider round"></span>
                </label>
              </> : null
            }
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
      <div className="test-price">
          <div 
            className="change-price low-price"
            onClick={() => handlePrice(false)}
          >
            <b>↓</b>
          </div>
          <p><b>{"Ξ "}</b>{ethPrice}</p>
          <div 
            className="change-price high-price"
            onClick={() => handlePrice(true)}
            >
            <b>↑</b>
          </div>
      </div>
    </div>
  )
}
