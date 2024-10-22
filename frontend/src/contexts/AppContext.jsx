import { createContext, useState, useContext, useCallback } from "react"
import { useSDK } from "@metamask/sdk-react"
import { formatUnits, parseUnits } from "@ethersproject/units"
import { BigNumber } from "@ethersproject/bignumber"

import Web3 from "web3"

import { QUID, SDAI,  MO, SUSDE, addressQD, addressSDAI, addressSUSDE, addressMO } from "../utils/constant"

const contextState = {
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
  account: "",
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

  const [mo, setMO] = useState(null)
  const [susde, setSusde] = useState(null)

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
        return (isProcessing ? 'off' : 'on')
      } else {
        return ('off')
      }
    } catch ( error ){
      console.error(error)
    }
  }, [])

  const getTotalSupply = useCallback(async () => {
    try {
      if (account && connected && quid && currentTimestamp) {
        const timestamp = await quid.methods.blocktimestamp().call()

        setAccountTimestamp(Number(timestamp))
        
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
  }, [setAccountTimestamp, account, connected, currentTimestamp, quid])

  const getSales = useCallback(async () => {
    try {

      if (account && quid && sdai && addressQD && mo && addressMO) {

        const days = await quid.methods.DAYS().call()

        const startDate = await quid.methods.START().call()

        const salesInfo = {
          mintPeriodDays: String(Number(days) / SECONDS_IN_DAY),
          smartContractStartTimestamp: startDate.toString()
        }

        return salesInfo
      }
      return null
    } catch (error) {
      console.error("Some problem with updateInfo, Summary.js, l.22: ", error)
    }
  }, [account, sdai, quid, mo])

  const getTotalInfo = useCallback(async () => {
    try {
      if (connected && account && quid && sdai && addressQD) {
        const totalSupply = await quid.methods.totalSupply().call()
        const formattedTotalMinted = formatUnits(totalSupply, 18).split(".")[0]

        const balance = await susde.methods.balanceOf(addressMO).call()
        const formattedTotalDeposited = formatUnits(balance, 18)

        if (totalMint !== formattedTotalMinted) setTotalMinted(formattedTotalMinted)

        if (totalDeposite !== formattedTotalDeposited) setTotalDeposited(formattedTotalDeposited)

        const totalInfo = {
          total_dep: formattedTotalDeposited,
          total_mint: formattedTotalMinted
        }

        if (formattedTotalDeposited && formattedTotalMinted) return totalInfo
      }
    } catch (error) {
      console.error("Error in updateInfo: ", error)
    }
  }, [setTotalMinted, setTotalDeposited, account, connected, quid, sdai, susde, totalMint, totalDeposite])

  const getUserInfo = useCallback(async () => {
    try {
      if (connected && account && quid) {
        const timestamp = await quid.methods.blocktimestamp().call()
        
        setAccountTimestamp(Number(timestamp.toString()))

        const qdAmount = parseUnits("1", 18).toBigInt()

        const data = await quid.methods.qd_amt_to_dollar_amt(qdAmount, currentTimestamp).call()

        const value = Number(formatUnits(data, 18) * 100)

        const price = BigNumber.from(Math.floor(value).toString())

        const info = await mo.methods.get_info(account).call()
        const actualUsd = Number(info[0]) / 1e18
        const actualQD = Number(info[1]) / 1e18

        setPrice(price)
        if (UsdBalance !== actualUsd) setUsdBalance(actualUsd)
        if (localMinted !== actualQD) setLocalMinted(actualQD)

        const userInfo = {
          actualUsd: actualUsd, actualQD: actualQD, price: price, info: info
        }

        return userInfo
      }
    } catch (error) {
      console.warn(`Failed to get account info:`, error)
    }
  }, [setPrice, setLocalMinted, setUsdBalance, 
    quid, account, connected, currentTimestamp, mo, localMinted, UsdBalance])

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
  }, [setSdaiBalance, account, sdai])

  const getQdBalance = useCallback(async () => {
    try {
      if (quid && account) {
        const balance = await quid.methods.balanceOf(account).call()

        setQdBalance(parseFloat(balance) / 1e18)
      }
    } catch (error) {
      console.warn(`Failed to connect:`, error)
    }
  }, [setQdBalance, account, quid])

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
  }, [setLocalMinted, setTotalDeposited, setTotalMinted, setPrice, setUsdBalance])

  const connectToMetaMask = useCallback(async () => {
    try {
      if (!account) {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' })
        
        setAccount(accounts[0])

        if (accounts && provider) {
          const web3Instance = new Web3(provider)
          const quidContract = new web3Instance.eth.Contract(QUID, addressQD)
          const moContract = new web3Instance.eth.Contract(MO, addressMO)
          const usdeContract = new web3Instance.eth.Contract(SDAI, addressSDAI)
          const susdeContract = new web3Instance.eth.Contract(SUSDE, addressSUSDE)

          setMO(moContract)
          setQuid(quidContract)
          setSdai(usdeContract)
          setSusde(susdeContract)
        }
      }
    } catch (error) {
      console.warn(`Failed to connect:`, error)
    }
  }, [setAccount, setMO, setSdai, setSusde, setQuid, account, provider])


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
        setMO,
        account,
        addressMO,
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
        mo,
        SECONDS_IN_DAY
      }}
    >
      {children}
    </AppContext.Provider>
  )
}

export const useAppContext = () => useContext(AppContext)

export default AppContext
