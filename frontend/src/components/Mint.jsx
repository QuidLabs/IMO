import { useCallback, useEffect, useState, useRef } from "react"
import { formatUnits, parseUnits } from "@ethersproject/units"

import { Modal } from "./Modal"
import { Icon } from "./Icon"

import { numberWithCommas } from "../utils/number-with-commas"

import { Buttons } from "./Adds/Buttons"
import { VoteButton } from "./VoteButton"

import { useAppContext } from "../contexts/AppContext"

import "./Styles/Mint.scss"

const ChoiseBoxes = ({
  currency = true,
  hide = false, status = true, boxType = true,
  name = "", relation = "",
  style = {}, onChange = () => { return null }
}) => {
  return (
    <>
      {hide ? null : boxType ? (
        <>
          <input
            id={`checkbox-${name}`}
            name={name}
            className="mint-checkBox"
            type="checkbox"
            checked={status}
            style={style ? style : null}
            onChange={() => onChange()}
          />
          <label htmlFor={`checkbox-${name}`} className="mint-availabilityMax">{relation}</label>
        </>
      ) : (
        <>
          <span className="mint-switcher mint-availabilityMax">{currency ? 
          <>
            <b style={{ color: '#4ad300' }}>{relation}</b>
          </> : <>{relation}</>
        }</span>
          <label className="switch">
            <input
              name={name}
              type="checkbox"
              checked={status}
              style={style ? style : null}
              onChange={() => onChange()}
            />
            <span className="slider round"></span>
          </label>
        </>
      )}
    </>
  )
}

const TestPrice = () => {
  const { account, quid } = useAppContext()

  const [price, setETHPrice] = useState('')

  const handlePrice = useCallback(async (status = null) => {
    try {
      if (status === null) await quid.methods.getPrice().call()
        .then((value) => { setETHPrice(parseFloat(value) / 1e18) })
      else await quid.methods.set_price_eth(status, false).send({ from: account })
        .then(async () => {
          await quid.methods.getPrice().call()
            .then((value) => { setETHPrice(parseFloat(value) / 1e18) })
        })
    } catch (error) {
      console.error("Test's pricing error", error)
    }
  }, [account, quid])

  useEffect(() => {
    handlePrice(null)
  }, [handlePrice])

  return (
    <>
      <div className="test-price">
        <div
          className="change-price low-price"
          onClick={() => handlePrice(false)}
        >
          <b>↓</b>
        </div>
        <p><b>{"Ξ "}</b>{parseFloat(price ? price : 0).toFixed(4)}</p>
        <div
          className="change-price high-price"
          onClick={() => handlePrice(true)}
        >
          <b>↑</b>
        </div>
      </div>
    </>
  )

}

export const Mint = () => {
  const DELAY = 60 * 60 * 8

  const { getTotalSupply, setStorage, getWalletBalance, getDepositInfo, getTotalInfo,
    addressQD, addressSDAI, account, connected, chooseButton, swipeStatus, currentPrice, notifications, quid, sdai, mo, addressMO } = useAppContext()

  const [inputValue, setInputValue] = useState('')
  const [sdaiValue, setSdaiValue] = useState('')

  const [totalSupplyCap, setTotalSupplyCap] = useState(0)
  const [isSameBeneficiary, setIsSameBeneficiary] = useState(true)
  const [beneficiary, setBeneficiary] = useState('')
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [startMsg, setStartMsg] = useState('')

  const [insureStatus, setInsureStatus] = useState(true)

  const [chooseCurrency, setChooseCurrency] = useState(false)
  const [choiseCurrency, setCurrency] = useState('QUID')

  const [transactionPrice, setTransactionPrice] = useState('')

  const [insureble, setInsureble] = useState('')

  const [voteStatus, setVoteStatus] = useState(false)

  const [buttonSign, setSign] = useState('')
  const [placeHolder, setPlaceHolder] = useState('Mint amount')

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

  const calculateEthTransaction = useCallback(async () => {
    try {
      await mo.methods.FEE().call()
        .then((value) => {
          const ethPrice = (Number(value) / 1e18) * inputValue

          setTransactionPrice(ethPrice.toFixed(4))
        })
    } catch (error) {
      console.error(error)
    }
  }, [mo, inputValue])

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
      await Promise.all([getTotalSupply(), getDepositInfo(addressMO), getTotalInfo()])
        .then((value) => {
          const deposit = value[2].total_dep
          const wethUsdBalance = value[1].weth_usd_balance
          const price = value[1].ethPrice

          setTotalSupplyCap(value[0])
          setInsureble(deposit - (wethUsdBalance * price))
        })
    } catch (error) {
      console.error(error)
    }
  }, [getDepositInfo, getTotalInfo, getTotalSupply, addressMO])

  const handleChangeValue = useCallback((e) => {
    const regex = /^\d*(\.\d*)?$|^$/

    let originalValue = e.target.value

    if (originalValue.length > 1 && originalValue[0] === "0" && originalValue[1] !== ".")
      originalValue = originalValue.substring(1)

    if (originalValue[0] === ".") originalValue = "0" + originalValue

    if (regex.test(originalValue)) {
      if (chooseButton === "MINT" || !chooseCurrency) {
        setSdaiValue(currentPrice * 0.01)
        setInputValue(Number(originalValue).toFixed())
      }
      else {
        setInputValue(originalValue)
        setSdaiValue(currentPrice * 0.01)
      }
    }
  }, [chooseButton, currentPrice, chooseCurrency])

  const setNotifications = useCallback((severity, message, status = false) => {
    setStorage(prevNotifications => [
      ...prevNotifications,
      { severity: severity, message: message, status: status }
    ])
  }, [setStorage])

  //================================================================================================
  // -------------------------- STARTING TRANSFERS TERMINAL METHOD ---------------------------------
  //================================================================================================

  const terminalStarting = async (button) => {
    const beneficiaryAccount = !isSameBeneficiary && beneficiary !== "" ? beneficiary : account
    const hasAgreedToTerms = localStorage.getItem("hasAgreedToTerms") === "true"

    if (!hasAgreedToTerms) return setIsModalOpen(true)

    if (!isSameBeneficiary && beneficiary === "") return setNotifications("error", "Please select a beneficiary", false)

    if (!account) return setNotifications("error", "Please connect your wallet")

    if (!inputValue.length) return setNotifications("error", "Please enter amount")

    const depInfo = await getDepositInfo()
      .then((numbers) => {
        return numbers
      })

    const ballanceStatus = await getWalletBalance().then((balance) => {
      if (Number(inputValue) > Number(balance.eth)) return true
      else return false
    })

    //By default the weth and work ballance are equals zero, so cindition for DEBIT/WITHDRAW will not work with this values
    //const depositBuffer = ethPrice * depInfo.work_eth_balance - depInfo.work_usd_balance

    const sDAIbalance = async () => {
      if (sdai) return Number(formatUnits(await sdai.methods.balanceOf(account).call(), 18))
    }

    try {
      if (button === "MINT") {
        if (inputValue < 50) return setNotifications("error", "The amount should be more than 50")

        if (inputValue > totalSupplyCap) return setNotifications("error", "The amount should be less than the maximum mintable QD")

        if (inputValue > (await sDAIbalance())) return setNotifications("error", "Cost shouldn't be more than your sDAI balance")

        const qdAmount = parseUnits(inputValue, 18)
        setIsProcessing(true)
        setNotifications("info", "Processing. Please don't close or refresh page when terminal is working")
        setInputValue("")

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

        setNotifications("info", `Start minting:\nQD amount: ${inputValue}\nCurrent account: ${account}\nAllowance: ${formatUnits(allowanceBeforeMinting, 18)}`)

        if (account) {
          await quid.methods.mint(
            beneficiaryAccount.toString(),
            qdAmount.toString(),
            addressSDAI.toString(), false).send({ from: account })
        }
        setNotifications("success", "Your minting is pending!", true)
      }

      if (button === "DEPOSIT") {
        if (!chooseCurrency && inputValue > (await sDAIbalance())) return setNotifications("error", "Cost shouldn't be more than your sDAI balance")

        if (!chooseCurrency && inputValue > insureble) return setNotifications("error", "The amount shouldn't be more than insurable")

        if (chooseCurrency && ballanceStatus) return setNotifications("error", "Cost shouldn't be more than your Etherum balance")

        // depositeBuffer using for this condition
        //if (chooseCurrency && inputValue > depositBuffer) return setNotifications("error", "The amount shouldn't be more than work and weth balance")

        const valueDepo = parseUnits(inputValue, 18).toString()

        setIsProcessing(true)
        setNotifications("info", "Processing. Please don't close or refresh page when terminal is working")
        setInputValue("")

        if (account && chooseCurrency) {
          await mo.methods.deposit(
            beneficiaryAccount.toString(),
            0, !insureStatus).send({ from: account, value: valueDepo })
        }

        if (account && !chooseCurrency) {
          const matureBallance = await quid.methods.matureBalanceOf(account).call()
            .then(value => {
              const mature = parseFloat(value) / 1e18
              return mature
            })

          if (inputValue <= matureBallance) await mo.methods.redeem(valueDepo).send({ from: account })
          else await quid.methods.transfer(addressMO, valueDepo).send({ from: account })
        }

        setNotifications("success", "Your deposit has been pending completed!", true)
      }

      if (button === "WITHDRAW") {
        if (!chooseCurrency && inputValue > (await sDAIbalance())) return setNotifications("error", "Cost shouldn't be more than your sDAI balance")

        if (!chooseCurrency && inputValue > insureble) return setNotifications("error", "The amount shouldn't be more than insurable")

        if (chooseCurrency && ballanceStatus) return setNotifications("error", "Cost shouldn't be more than your Etherum balance")

        if (chooseCurrency && inputValue > depInfo.work_eth_balance) {
          const foldValue = (inputValue - depInfo.work_eth_balance).toString()

          const parseFold = parseUnits(foldValue, 18).toString()

          await mo.methods.fold(account, parseFold, false).send({ from: account })
        }

        const withDrawValue = parseUnits(inputValue, 18).toString()

        setIsProcessing(true)
        setNotifications("info", "Processing. Please don't close or refresh page when terminal is working")
        setInputValue("")

        if (account) {
          await mo.methods.withdraw(withDrawValue, !chooseCurrency).send({ from: account })
          setNotifications("success", "The withdraw has been pending completed!", true)
        }
      }
    } catch (err) {
      const er = "MO::mint: supply cap exceeded"
      const msg = err.error?.message === er || err.message === er ? "Please wait for more QD to become mintable..." : err.error?.message || err.message

      setNotifications("error", msg)
    } finally {
      setIsProcessing(false)
      setInputValue("")
    }
  }

  //================================================================================================
  // -------------------------- THE END OF WALLET TERMINAL METHOD ----------------------------------
  //================================================================================================

  const handleSubmit = () => {
    terminalStarting(chooseButton.current)
  }

  const handleSetMaxValue = async () => {
    if (inputRef.current > totalSupplyCap) setInputValue(totalSupplyCap)
    else inputRef.current.focus()
  }


  const handleVotes = useCallback(() => {
    if (voteStatus) setVoteStatus(false)
    else setVoteStatus(true)
  }, [voteStatus])

  const handleInsure = useCallback(() => {
    if (insureStatus) setInsureStatus(false)
    else setInsureStatus(true)
  }, [insureStatus])


  const handleWithdraw = useCallback(() => {
    if (chooseCurrency) {
      setChooseCurrency(false)
      setCurrency("QUID")
    }
    else {
      setChooseCurrency(true)
      setCurrency("ETH")
    }
  }, [chooseCurrency])

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
    } else if (chooseButton.current === "DEPOSIT") {
      if (!chooseCurrency) setSign('QD')
      else {
        calculateEthTransaction()
        setSign('Ξ')
      }

      setPlaceHolder('Deposit amount')
    } else if (chooseButton.current === "WITHDRAW" && !chooseCurrency) {
      setSign('QD')
      setPlaceHolder('Withdraw amount')
    } else {
      setSign('Ξ')
      setPlaceHolder('Withdraw amount')
    }
  }, [calculateEthTransaction, chooseButton, swipeStatus, chooseCurrency])

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
            value={inputValue}
            onChange={handleChangeValue}
            placeholder={placeHolder}
            ref={inputRef}
          />
          <div className="mint-dollarSign">
            <button id="mint-button">
              <div>{buttonSign}</div>
            </button>
          </div>
          <button className="mint-maxButton" onClick={handleSetMaxValue} type="button">
            Max
            <Icon preserveAspectRatio="none" className="mint-maxButtonBackground" name="btn-bg" />
          </button>
        </div>
        <div className="mint-sub">
          <div className="mint-subLeft">
            {chooseButton.current === "MINT" || chooseButton.current == null ?
              <>
                Cost in $
                <strong>
                  {inputValue === "" || inputValue === "0" ? "sDAI Amount" : numberWithCommas(calculatePrice(sdaiValue * inputValue))}
                </strong>
              </> : chooseButton.current === "DEPOSIT" && chooseCurrency ?
                (<>
                  Cost for Ξ
                  <strong>
                    {inputValue === "" || inputValue === "0" ? "ETH Amount" : transactionPrice}
                  </strong>
                </>)
                : null}
          </div>
          {inputValue && inputValue !== "0" && (chooseButton.current === "MINT" || chooseButton.current == null) ? (
            <div className="mint-subRight">
              <strong style={{ color: "#02d802" }}>
                ${numberWithCommas((+inputValue - sdaiValue).toFixed())}
              </strong>
              Future profit
            </div>
          ) : null}
          <label className="checkbox-container">
            {chooseButton.current === "DEPOSIT" ?
              <ChoiseBoxes
                hide={!chooseCurrency}
                status={insureStatus}
                boxType={true}
                name={"insure"}
                relation={"INSURING"}
                onChange={handleInsure}
              /> : null
            }
            {chooseButton.current === "MINT" || chooseButton.current == null || chooseButton.current === "DEPOSIT" ?
              <ChoiseBoxes
                hide={chooseButton.current === "MINT" || chooseButton.current == null ? false : !chooseCurrency}
                status={isSameBeneficiary}
                boxType={true}
                name={"tomyself"}
                relation={"to myself"}
                onChange={() => setIsSameBeneficiary(!isSameBeneficiary)}
              /> : null
            }
            {chooseButton.current === "WITHDRAW" || chooseButton.current === "DEPOSIT" ?
              <ChoiseBoxes
                status={chooseCurrency}
                boxType={false}
                name={"currency"}
                relation={choiseCurrency}
                onChange={handleWithdraw}
              /> : null
            }
          </label>
        </div>
        <Buttons
          names={["WITHDRAW", "MINT", "DEPOSIT"]}
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
      <div className="mint-bottom">
        <div className="mint-vote-box">
          <ChoiseBoxes
            status={voteStatus}
            boxType={false}
            name={"vote"}
            currency={false}
            relation={voteStatus ? "Choise value and click for the vote:" : "Vote for the deductible!"}
            onChange={() => handleVotes()}
          />
        </div>
        {voteStatus ? <VoteButton minValue={1} maxValue={9}/> : <TestPrice /> }
      </div>
    </div>
  )
}
