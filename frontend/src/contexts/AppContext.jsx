import { createContext, useState, useContext, useCallback } from "react"
import { useSDK } from "@metamask/sdk-react"
import { formatUnits, parseUnits } from "@ethersproject/units"
import { BigNumber } from "@ethersproject/bignumber"

import Web3 from "web3"

import { QUID, MO, USDE, addressMO, addressQD, addressUSDE } from "../utils/constant"

const contextState = {
  account: "",
  connectToMetaMask: () => { },
  getUsde: () => { },
  getSales: () => { },
  getTotalInfo: () => { },
  getUserInfo: () => { },
  getTotalSupply: () => { },
  setAllInfo: () => { },
  connected: false,
  connecting: false,
  provider: {},
  sdk: {},
  web3: {}
}

const AppContext = createContext(contextState)

export const AppContextProvider = ({ children }) => {
  const [account, setAccount] = useState("")
  const { sdk, connected, connecting, provider } = useSDK()

  const [quid, setQuid] = useState(null)
  const [usde, setUsde] = useState(null)
  const [mo, setMO] = useState(null)

  const [QDbalance, setQDbalance] = useState(null)
  const [usdeBalance, setUsdeBalance] = useState(null)

  const [UsdBalance, setUsdBalance] = useState(null)
  const [localMinted, setLocalMinted] = useState(null)

  const [totalDeposited, setTotalDeposited] = useState("")
  const [totalMint, setTotalMinted] = useState("")
  const [currentPrice, setPrice] = useState(null)

  const [currentTimestamp, setAccountTimestamp] = useState(0)

  const SECONDS_IN_DAY = 86400

  const getTotalSupply = useCallback(async () => {
    try {
      setAccountTimestamp((Date.now() / 1000).toFixed(0))

      if (account && connected && quid && currentTimestamp) {
        const currentTimestampBN = currentTimestamp.toString()

        const [totalSupplyCap] = await Promise.all([
          quid.methods.get_total_supply_cap(currentTimestampBN).call(),
          quid.methods.totalSupply().call()
        ])

        const totalCapInt = totalSupplyCap ? parseInt(formatUnits(totalSupplyCap, 18)) : null

        if (totalCapInt) return totalCapInt
      }
    } catch (error) {
      console.error("Some problem with getSupply: ", error)
      return null
    }
  }, [account, connected, currentTimestamp, quid])

  const getSales = useCallback(async () => {
    try {
      if (account && quid && usde && mo && addressQD && addressMO) {
        const days = await quid.methods.DAYS().call()
        const startDate = await quid.methods.START_DATE().call()

        const salesInfo = {
          mintPeriodDays: String(Number(days) / SECONDS_IN_DAY),
          smartContractStartTimestamp: startDate.toString()
        }

        return salesInfo
      }
      return null
    } catch (error) {
      console.error("Some problem with updateInfo, Summary.js, l.22: ", error)
      return null
    }
  }, [account, usde, quid])

  const getTotalInfo = useCallback(async () => {
    try {
      setAccountTimestamp((Date.now() / 1000).toFixed(0))

      if (connected && account && quid && usde && addressQD) {
        const qdAmount = parseUnits("1", 18).toBigInt()

        const data = await quid.methods.qd_amt_to_dollar_amt(qdAmount, currentTimestamp).call()

        const value = Number(formatUnits(data, 18) * 100)

        const bigNumber = BigNumber.from(Math.floor(value).toString())

        const totalSupply = await quid.methods.totalSupply().call()
        const formattedTotalMinted = formatUnits(totalSupply, 18).split(".")[0]

        if (totalMint !== formattedTotalMinted) setTotalMinted(formattedTotalMinted)

        // TODO susde
        const balance = await usde.methods.balanceOf(addressQD).call()
        const formattedTotalDeposited = formatUnits(balance, 18)

        if (totalDeposited !== formattedTotalDeposited) setTotalDeposited(formattedTotalDeposited)

        if (formattedTotalDeposited && formattedTotalMinted && bigNumber) {
          return { total_dep: formattedTotalDeposited, total_mint: formattedTotalMinted, price: bigNumber.toString() }
        }
      }
    } catch (error) {
      console.error("Error in updateInfo: ", error)
    }
  }, [account, connected, quid, usde, currentTimestamp, totalMint, totalDeposited])

  const getUserInfo = useCallback(async () => {
    try {
      setAccountTimestamp((Date.now() / 1000).toFixed(0))

      if (connected && account && quid) {

        const qdAmount = parseUnits("1", 18).toBigInt()

        const data = await quid.methods.qd_amt_to_dollar_amt(qdAmount, currentTimestamp).call()

        const value = Number(formatUnits(data, 18) * 100)

        const bigNumber = BigNumber.from(Math.floor(value).toString())

        const info = await quid.methods.get_info(account).call()
        const actualUsd = Number(info[0]) / 1e18
        const actualQD = Number(info[1]) / 1e18

        setPrice(bigNumber.toString())
        setUsdBalance(actualUsd)
        setLocalMinted(actualQD)

        return { actualUsd: actualUsd, actualQD: actualQD, price: bigNumber.toString(), info: info }
      }
    } catch (error) {
      console.warn(`Failed to get account info:`, error)
      return null
    }
  }, [quid, account, currentTimestamp, connected])

  const getUsde = useCallback(async () => {
    try {
      console.log("usde 0")

      if (account && usde) {
        await usde.methods.mint(account).send({ from: account })

        console.log("ACCOUNT: ", account)
      }
    } catch (error) {
      console.warn(`Failed to connect:`, error)
    }
  }, [account, usde])

  const getUsdeBalance = useCallback(async () => {
    try {
      if (usde && account) {
        const balance = await usde.methods.balanceOf(account).call()

        setUsdeBalance(parseFloat(balance) / 1e18)
      }
    } catch (error) {
      console.warn(`Failed to connect:`, error)
    }
  }, [account, usde])

  const getQDbalance = useCallback(async () => {
    try {
      if (quid && account) {
        const balance = await quid.methods.balanceOf(account).call()

        setQDbalance(parseFloat(balance) / 1e18)
      }
    } catch (error) {
      console.warn(`Failed to connect:`, error)
    }
  }, [account, quid])

  const setAllInfo = useCallback(async (
    balance, localMinted, totalDeposited, totalMinted, QDprice, reset = false
  ) => {
    try {
      setUsdBalance(balance)
      setLocalMinted(localMinted)

      setTotalDeposited(totalDeposited)
      setTotalMinted(totalMinted)
      setPrice(QDprice)

      if (reset) setAccount("")
    } catch (error) {
      console.warn(`Failed to set all info:`, error)
    }
  }, [])

  const connectToMetaMask = useCallback(async () => {
    try {
      if (!account) {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' })
        setAccount(accounts[0])

        if (accounts && provider) {
          const web3Instance = new Web3(provider)
          const quidContract = new web3Instance.eth.Contract(QUID, addressQD)
          const moContract = new web3Instance.eth.Contract(MO, addressMO)
          const usdeContract = new web3Instance.eth.Contract(USDE, addressUSDE)
          setMO(moContract)
          setQuid(quidContract)
          setUsde(usdeContract)

        }
      }
    } catch (error) {
      console.warn(`Failed to connect:`, error)
    }
  }, [account, provider])


  return (
    <AppContext.Provider
      value={{
        account,
        connectToMetaMask,
        getUsde,
        getTotalInfo,
        getUserInfo,
        getSales,
        getTotalSupply,
        setAllInfo,
        getUsdeBalance, 
        getQDbalance, 
        connected,
        connecting,
        currentTimestamp,
        provider,
        sdk,
        mo,
        quid,
        usde,
        QDbalance,
        usdeBalance,
        addressQD,
        addressMO,
        addressUSDE,
        currentPrice,
        UsdBalance,
        localMinted,
        totalDeposited,
        totalMint,
        SECONDS_IN_DAY
      }}
    >
      {children}
    </AppContext.Provider>
  )
}

export const useAppContext = () => useContext(AppContext)

export default AppContext
