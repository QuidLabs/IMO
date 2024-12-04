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
            className="mint-checkBox fade-in"
            type="checkbox"
            checked={status}
            style={style ? style : null}
            onChange={() => onChange()}
          />
          <label htmlFor={`checkbox-${name}`} className="mint-availabilityMax fade-in">{relation}</label>
        </>
      ) : (
        <>
          <span className="mint-switcher mint-availabilityMax">{currency ?
            <>
              <b style={{ color: '#4ad300' }} className="fade-in">{relation}</b>
            </> : <>{relation}</>
          }</span>
          <label className="switch fade-in">
            <input
              name={name}
              type="checkbox"
              className="fade-in"
              checked={status}
              style={style ? style : null}
              onChange={() => onChange()}
            />
            <span className="slider round fade-in"></span>
          </label>
        </>
      )}
    </>
  )
}

const TestPrice = () => {
  const { account, mo } = useAppContext()

  const [price, setETHPrice] = useState('')

  const handlePrice = useCallback(async (status = null) => {
    try {
      if (account) {
        if (status === null) await mo.methods.getPrice(42).call()
          .then((value) => { setETHPrice(parseFloat(value) / 1e18) })
        else await mo.methods.set_price_eth(status, false).send({ from: account })
          .then(async () => {
            await mo.methods.getPrice(42).call()
              .then((value) => { setETHPrice(parseFloat(value) / 1e18) })
          })
      }
    } catch (error) {
      console.error("Test's pricing error", error)
    }
  }, [account, mo])

  useEffect(() => {
    handlePrice(null)
  }, [handlePrice])

  return (
    <>
      <div className="fade-in">
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
      </div>
    </>
  )

}

export const Mint = () => {
  const DELAY = 60 * 60 * 8

  const { getTotalSupply, setStorage, setSwipe, getWalletBalance, getDepositInfo, getUserInfo,
    addressQD, addressUSDE, account, connected, chooseButton, swipeStatus, currentPrice, notifications, quid, usde, mo, addressMO } = useAppContext()

  const [inputValue, setInputValue] = useState('')
  const [usdeValue, setusdeValue] = useState('')

  const [totalSupplyCap, setTotalSupplyCap] = useState(0)
  const [isSameBeneficiary, setIsSameBeneficiary] = useState(true)
  const [beneficiary, setBeneficiary] = useState('')
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [startMsg, setStartMsg] = useState('')

  const [insureStatus, setInsureStatus] = useState(true)

  const [chooseCurrency, setChooseCurrency] = useState(false)
  const [choiseCurrency, setCurrency] = useState('QUID')

  const [transactionPrice, setTransactionPrice] = useState('')

  const [insurable, setInsurable] = useState('')

  const [voteStatus, setVoteStatus] = useState(false)

  const [walletEthBalance, setWalletEthBalance] = useState(null)
  const [walletUSDeBalances, setWalletUSDeBalances] = useState(null)

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

  const qdAmountTousdeAmt = useCallback(async (qdAmount, delay = 0) => {
    const qdAmountBN = qdAmount ? qdAmount.toString() : 0

    return quid ? await quid.methods.qd_amt_to_dollar_amt(qdAmountBN).call() : 0
  }, [quid])

  const handleChangeValue = useCallback((e) => {
    const regex = /^\d*(\.\d*)?$|^$/

    let originalValue = e.target.value

    if (originalValue.length > 1 && originalValue[0] === "0" && originalValue[1] !== ".")
      originalValue = originalValue.substring(1)

    if (originalValue[0] === ".") originalValue = "0" + originalValue

    if (regex.test(originalValue)) {
      if (chooseButton.current === "MINT" || !chooseCurrency || chooseButton == null) setInputValue(Number(originalValue).toFixed())
      else setInputValue(originalValue)
    }
  }, [chooseButton, chooseCurrency])

  const setNotifications = useCallback((severity, message, status = false) => {
    setStorage(prevNotifications => [
      ...prevNotifications,
      { severity: severity, message: message, status: status }
    ])
  }, [setStorage])

  const updateTotalSupply = useCallback(async () => {
    try {
      await Promise.all([getTotalSupply(), getDepositInfo(addressMO), getWalletBalance()])
        .then(async (value) => {
          const carryDebit = await getUserInfo(addressMO).then(userInfo => {return userInfo.actualUsd})

          const wethEthBalance = value[1].weth_usd_balance
          const price = value[1].ethPrice

          var insurableValue = 0
          if (wethEthBalance > 0) {
            if (chooseButton.current === "DEPOSIT") {
              insurableValue = (wethEthBalance * price) - carryDebit   
            }
          }
          if (chooseButton.current === "DEPOSIT") {
            insurableValue = carryDebit
          }
          setTotalSupplyCap(value[0])

          setInsurable(insurableValue > 0 ? insurableValue : 0)

          setWalletEthBalance(value[2].eth)
          setWalletUSDeBalances(value[2].usde)
        })
    } catch (error) {
      console.error(error)
    }
  }, [getDepositInfo, getTotalSupply, getWalletBalance, getUserInfo, addressMO, chooseButton])

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

    const balanceStatus = await getWalletBalance().then((balance) => {
      if (Number(inputValue) > Number(balance.eth)) return true
      else return false
    })

    //By default the weth and work balance are equals zero, so cindition for DEBIT/WITHDRAW will not work with this values
    const ethPrice = await mo.methods.getPrice(42).call()
    const parseEthPrice = parseFloat(ethPrice) / 1e18

    const usdebalance = async () => {
      if (usde) return Number(formatUnits(await usde.methods.balanceOf(account).call(), 18))
    }

    try {
      if (button === "MINT") {
        if (inputValue < 50) return setNotifications("error", "The amount should be more than 50")

        if (inputValue > totalSupplyCap) return setNotifications("error", "The amount should be less than the maximum mintable QD")

        if (inputValue > (await usdebalance())) return setNotifications("error", "Cost shouldn't be more than your usde balance")

        const qdAmount = parseUnits(inputValue, 18)
        setIsProcessing(true)
        setNotifications("info", "Processing. Please don't close or refresh page when terminal is working")
        setInputValue("")

        const usdeAmount = await qdAmountTousdeAmt(qdAmount, DELAY)
        const usdeString = usdeAmount ? usdeAmount.toString() : 0

        const allowanceBigNumber = await usde.methods.allowance(account, addressQD).call()
        const allowanceBigNumberBN = allowanceBigNumber ? allowanceBigNumber.toString() : 0

        setNotifications("info", `Start minting:\nCurrent allowance: ${formatUnits(allowanceBigNumberBN, 18)}\nNote amount: ${formatUnits(usdeString, 18)}`)

        setNotifications("info", "Please, approve minting in your wallet.")

        if (account) await usde.methods.approve(addressQD.toString(), usdeAmount.toString()).send({ from: account })

        setNotifications("info", `Start minting:\nCurrent allowance: ${formatUnits(allowanceBigNumberBN, 18)}\nNote amount: ${formatUnits(usdeString, 18)}`)

        setNotifications("success", "Please wait for approving")

        setNotifications("info", "Minting...")

        setNotifications("success", "Please check your wallet")

        const allowanceBeforeMinting = await usde.methods.allowance(account, addressQD).call()

        setNotifications("info", `Start minting:\nQD amount: ${inputValue}\nCurrent account: ${account}\nAllowance: ${formatUnits(allowanceBeforeMinting, 18)}`)

        if (account) {
          await quid.methods.mint(
            beneficiaryAccount.toString(),
            qdAmount.toString(),
            addressUSDE.toString(), false).send({ from: account })
        }
        setNotifications("success", "Your minting is pending!", true)
      }

      if (button === "DEPOSIT") {
        const workUsdBalance = await getDepositInfo().then(depositInfo => {return depositInfo.work_usd_balance})
        
        if (!chooseCurrency && inputValue > workUsdBalance) return setNotifications("error", "Cost shouldn't be more than your owed USDe balance. Use The QD's withdrow for top up your account.")
        if (chooseCurrency && balanceStatus) return setNotifications("error", "Cost shouldn't be more than your Etherum balance")
        if (chooseCurrency && insureStatus && inputValue*parseEthPrice > insurable) return setNotifications("error", "The amount shouldn't be more than insurable")

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
          const maturebalance = await quid.methods.matureBalanceOf(account).call()
            .then(value => {
              const mature = parseFloat(value) / 1e18
              return mature
            })

          if (inputValue <= maturebalance) await mo.methods.redeem(valueDepo).send({ from: account })
          else if (inputValue <= workUsdBalance) await quid.methods.transfer(addressMO, valueDepo).send({ from: account })
        }

        setNotifications("success", "Your deposit has been pending completed!", true)
      }

      if (button === "WITHDRAW") {
        if (!chooseCurrency && inputValue > (await usdebalance())) return setNotifications("error", "Cost shouldn't be more than your usde balance")

        if (!chooseCurrency && inputValue > depInfo.work_eth_balance + depInfo.weth_usd_balance) return setNotifications("error", "The amount shouldn't be more than deposited")

        if (chooseCurrency && balanceStatus) return setNotifications("error", "Cost shouldn't be more than your Etherum balance")

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

  const handleSetMaxValue = useCallback(async () => {
    if (!chooseCurrency || buttonRef.current === "MINT") {
      const setUSDeValue = Number(walletUSDeBalances).toFixed()
      setInputValue(setUSDeValue.toString())
    }
    else setInputValue(walletEthBalance)
  }, [chooseCurrency, walletEthBalance, walletUSDeBalances])


  const handleVotes = useCallback(() => {
    if (voteStatus) setVoteStatus(false)
    else setVoteStatus(true)
  }, [voteStatus])

  const handleInsure = useCallback(() => {
    if (insureStatus) setInsureStatus(false)
    else setInsureStatus(true)
  }, [insureStatus])


  const handleCurrency = useCallback(() => {
    if (chooseCurrency) {
      setChooseCurrency(false)
      setCurrency("QUID")
      setInputValue("")
      setInsureStatus(true)
      setIsSameBeneficiary(true)
    }
    else {
      setChooseCurrency(true)
      setCurrency("ETH")
      setInputValue("")
    }
  }, [chooseCurrency])

  useEffect(() => {
    if (quid) {
      updateTotalSupply()
      setusdeValue(currentPrice * 0.01)
    }

    if (consoleRef.current) consoleRef.current.scrollTop = consoleRef.current.scrollHeight

    if (account && connected && quid) setStartMsg('Terminal started. Mint is available!')
    else {
      localStorage.setItem("consoleNotifications", JSON.stringify(''))
    }

    if (notifications[0] && !connected) setTimeout(() => setStorage([]), 500)

  }, [updateTotalSupply, setStorage, account, connected, currentPrice, quid, notifications, swipeStatus])

  useEffect(() => {
    if (swipeStatus) {
      setInputValue("")
      setInsureStatus(true)
      setIsSameBeneficiary(true)
      setSwipe()
    }

    if (chooseButton.current === "MINT" || chooseButton.current == null) {
      setSign('QD')
      setPlaceHolder('Mint amount')
      setChooseCurrency(false)
      setCurrency("QUID")
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
  }, [calculateEthTransaction, setSwipe, chooseButton, swipeStatus, chooseCurrency])

  return (
    <div className="mint">
      <div className="mint-root fade-in" onSubmit={handleSubmit}>
        <div className="mint-header">
          <span className="mint-title">
            <span className="mint-totalSupply">
              {chooseButton.current === "MINT" || chooseButton.current == null ?
                (
                  <div className="fade-in">
                    <span style={{ fontWeight: 400, color: '#4ad300' }} className="fade-in">
                      {totalSupplyCap ? numberWithCommas(totalSupplyCap) : 0}
                      &nbsp;
                    </span>
                    QD mintable
                  </div>
                ) : (
                  <div className="fade-in">
                    <span style={{ fontWeight: 400, color: '#4ad300' }} className="fade-in">
                      {insurable ? numberWithCommas(Number(insurable).toFixed(0)) : 0}
                      &nbsp;
                    </span>
                    $ insurable
                  </div>
                )}
            </span>
          </span>
        </div>
        <div className="mint-inputContainer fade-in">
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
              <div className="fade-in">{buttonSign}</div>
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
              <div className="fade-in">
                Cost in $
                <strong>
                  {inputValue === "" || inputValue === "0" ? "usde Amount" : numberWithCommas(calculatePrice(usdeValue * inputValue))}
                </strong>
              </div> : chooseButton.current === "DEPOSIT" && chooseCurrency ?
                (<div className="fade-in">
                  Cost for Ξ
                  <strong>
                    {inputValue === "" || inputValue === "0" ? "ETH Amount" : transactionPrice}
                  </strong>
                </div>)
                : null}
          </div>
          {inputValue && inputValue !== "0" && (chooseButton.current === "MINT" || chooseButton.current == null) ? (
            <div className="mint-subRight">
              <strong style={{ color: "#02d802" }}>
                ${numberWithCommas((inputValue - usdeValue * inputValue).toFixed())}{" "}
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
                onChange={handleCurrency}
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
        {isSameBeneficiary ? <div className={`mint-beneficiaryContainer ${isSameBeneficiary ? "hide" : "show"}`}></div> :
          <div className={`mint-beneficiaryContainer ${isSameBeneficiary ? "hide" : "show"}`}>
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
          </div>}
        <Modal open={isModalOpen} handleAgree={handleAgreeTerms} handleClose={handleCloseModal} />
      </div>
      <div className="mint-console fade-in" ref={consoleRef}>
        <div className="mint-console-content">
          <div>{connected ? startMsg : 'Connect your MetaMask wallet...'}</div>
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
      {connected ? <div className="mint-bottom fade-in">
        <div className="mint-vote-box fade-in">
          <ChoiseBoxes
            status={voteStatus}
            boxType={false}
            name={"vote"}
            currency={false}
            relation={voteStatus ? "Choose a value and double click to vote:" : "Vote for the deductible!"}
            onChange={() => handleVotes()}
          />
        </div>
        {voteStatus ? <VoteButton minValue={1} maxValue={9} /> : <TestPrice />}
      </div> : null}
    </div>
  )
}
