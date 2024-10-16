import { createContext, useState, useContext, useCallback } from "react"
import { useSDK } from "@metamask/sdk-react"
import { formatUnits, parseUnits } from "@ethersproject/units"
import { BigNumber } from "@ethersproject/bignumber"

import Web3 from "web3"

import { QUID, SDAI, addressQD, addressSDAI } from "../utils/constant"

const contextState = {
  account: "",
  connectToMetaMask: () => { },
  getSdai: () => { },
  getSales: () => { },
  getTotalInfo: () => { },
  getUserInfo: () => { },
  getTotalSupply: () => { },
  setAllInfo: () => { },
  changeButton: () => { },
  setNotifications: () => { },
  setStorage: () => { },
  getStorage: () => { },
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
  const [sdai, setSdai] = useState(null)

  const [QDbalance, setQdBalance] = useState(null)
  const [SDAIbalance, setSdaiBalance] = useState(null)

  const [UsdBalance, setUsdBalance] = useState(null)
  const [localMinted, setLocalMinted] = useState(null)

  const [totalDeposite, setTotalDeposited] = useState("")
  const [totalMint, setTotalMinted] = useState("")
  const [currentPrice, setPrice] = useState(null)

  const [currentTimestamp, setAccountTimestamp] = useState(0)

  const [notifications, setNotifications] = useState('')

  const SECONDS_IN_DAY = 86400

  //Get storage

  const getStorage = useCallback(() => {
    try {
      //realizations
    } catch (error) {
      console.error("Error getting notifications:", error)
    }
  }, [])

  const setStorage = useCallback((newNotifications) => {
    try {
      setNotifications(newNotifications)

      localStorage.setItem("consoleNotifications", JSON.stringify(newNotifications))
    } catch (error) {
      console.error("Error setting notifications:", error)
    }
  }, [])

  const changeButton = useCallback((isProcessing, state) => {
    try{
      if (state) {
        return (isProcessing ? 'off' : 'on');
      } else {
        return ('off');
      }
    } catch ( error ){
      console.error(error)
    }
  }, [])

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
      if (account && quid && sdai && addressQD) {
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
  }, [account, sdai, quid])

  const getTotalInfo = useCallback(async () => {
    try {
      setAccountTimestamp((Date.now() / 1000).toFixed(0))

      if (connected && account && quid && sdai && addressQD) {
        const qdAmount = parseUnits("1", 18).toBigInt()

        const data = await quid.methods.qd_amt_to_dollar_amt(qdAmount, currentTimestamp).call()

        const value = Number(formatUnits(data, 18) * 100)

        const bigNumber = BigNumber.from(Math.floor(value).toString())

        const totalSupply = await quid.methods.totalSupply().call()
        const formattedTotalMinted = formatUnits(totalSupply, 18).split(".")[0]

        if (totalMint !== formattedTotalMinted) setTotalMinted(formattedTotalMinted)

        const balance = await sdai.methods.balanceOf(addressQD).call()
        const formattedTotalDeposited = formatUnits(balance, 18)

        if (totalDeposite !== formattedTotalDeposited) setTotalDeposited(formattedTotalDeposited)

        if (formattedTotalDeposited && formattedTotalMinted && bigNumber) {
          return { total_dep: formattedTotalDeposited, total_mint: formattedTotalMinted, price: bigNumber.toString() }
        }
      }
    } catch (error) {
      console.error("Error in updateInfo: ", error)
    }
  }, [account, connected, quid, sdai, currentTimestamp, totalMint, totalDeposite])

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

  const getSdai = useCallback(async () => {
    try {
      console.log("Sdai 0")

      if (account && sdai) {
        await sdai.methods.mint(account).send({ from: account })

        console.log("ACCOUNT: ", account)
      }
    } catch (error) {
      console.warn(`Failed to connect:`, error)
    }
  }, [account, sdai])

  const getSdaiBalance = useCallback(async () => {
    try {
      if (sdai && account) {
        const balance = await sdai.methods.balanceOf(account).call()

        setSdaiBalance(parseFloat(balance) / 1e18)
      }
    } catch (error) {
      console.warn(`Failed to connect:`, error)
    }
  }, [account, sdai])

  const getQdBalance = useCallback(async () => {
    try {
      if (quid && account) {
        const balance = await quid.methods.balanceOf(account).call()

        setQdBalance(parseFloat(balance) / 1e18)
      }
    } catch (error) {
      console.warn(`Failed to connect:`, error)
    }
  }, [account, quid])

  const setAllInfo = useCallback(async (gUSD, gSDAI, lUsd, lSdai, price, reset = false) => {
    try {
      setUsdBalance(gUSD)
      setLocalMinted(gSDAI)

      setTotalDeposited(lUsd)
      setTotalMinted(lSdai)
      setPrice(price)

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
          const sdaiContract = new web3Instance.eth.Contract(SDAI, addressSDAI)

          setQuid(quidContract)
          setSdai(sdaiContract)
        }
      } 
    } catch (error) {
      console.warn(`Failed to connect:`, error)
    }
  }, [account, provider])


  return (
    <AppContext.Provider
      value={{
        connectToMetaMask,
        getSdai,
        getTotalInfo,
        getUserInfo,
        getSales,
        getTotalSupply,
        setAllInfo,
        getSdaiBalance, 
        getQdBalance, 
        changeButton,
        setNotifications,
        setStorage,
        getStorage,
        account,
        connected,
        connecting,
        currentTimestamp,
        provider,
        sdk,
        quid,
        sdai,
        QDbalance,
        SDAIbalance,
        addressQD,
        addressSDAI,
        currentPrice,
        UsdBalance,
        localMinted,
        totalDeposite,
        totalMint,
        notifications,
        SECONDS_IN_DAY
      }}
    >
      {children}
    </AppContext.Provider>
  )
}

export const useAppContext = () => useContext(AppContext)

export default AppContext
