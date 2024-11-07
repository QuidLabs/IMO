import { useCallback, useEffect, useState } from "react"
import { useAppContext } from "../contexts/AppContext";
import { numberWithCommas } from "../utils/number-with-commas"

import "./Styles/MintBar.scss"

export const DepositeBar = () => {
    const { getDepositInfo, resetAccounts,
        account, connected, quid, sdai, addressQD, notifications } = useAppContext()

    const [totalDeposited, setTotalDeposited] = useState("")
    const [totalMinted, setTotalMinted] = useState("")
    const [gain, setGain] = useState("")
    const [price, setPrice] = useState("")

    const updatingInfo = useCallback(async () => {
        try {
            if (connected && account && quid && sdai && addressQD) {
                await Promise.all([getDepositInfo()])
                    .then(value => {
                        setTotalDeposited(value[0].work_eth_balance)
                        setTotalMinted(value[0].work_usd_balance)
                        setPrice(value[0].weth_eth_balance)
                        setGain(value[0].weth_usd_balance)
                    })
            } else resetAccounts(true)
        } catch (error) {
            console.error("Some problem with updateInfo, Summary.js, l.22: ", error)
        }
    }, [getDepositInfo, resetAccounts,
        account, addressQD, connected, sdai, quid])

    useEffect(() => {
        try {
            updatingInfo()
        } catch (error) {
            console.error("Some problem with sale's start function: ", error)
        }
    }, [resetAccounts, updatingInfo, connected, notifications])

    return (
        <div className={`summary-root`} >
            <div className="summary-section">
                <div className="summary-title">ETHerum's deposited:</div>
                <div className="summary-value">
                    Ξ{connected && account ? numberWithCommas(parseFloat(Number(totalDeposited).toFixed(2))) : 0}
                </div>
            </div>
            <div className="summary-section">
                <div className="summary-title">USDai's owed:</div>
                <div className="summary-value">
                    ${connected && account ? numberWithCommas(parseFloat(Number(totalMinted).toFixed(2))) : 0}
                </div>
            </div>
            <div className="summary-section">
                <div className="summary-title">ETHerum's insured:</div>
                <div className="summary-value">
                    <span className="summary-value">${connected && account ? parseFloat(Number(price).toFixed(2)) : 0}</span>
                </div>
            </div>
            <div className="summary-section">
                <div className="summary-title">USDai's value of the insured:</div>
                <div className="summary-value">
                    {connected && account ? parseFloat(Number(gain).toFixed(2)) : 0}
                </div>
            </div>
        </div>
    )
}
