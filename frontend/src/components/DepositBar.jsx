import { useCallback, useEffect, useState } from "react"
import { useAppContext } from "../contexts/AppContext";
import { numberWithCommas } from "../utils/number-with-commas"

import "./Styles/MintBar.scss"
import "./Styles/DepositeBar.scss"

export const DepositBar = ({address = null}) => {
    const { getDepositInfo, resetAccounts,
        account, connected, quid, usde, addressQD, notifications } = useAppContext()

    const [totalDeposited, setTotalDeposited] = useState("")
    const [totalMinted, setTotalMinted] = useState("")
    const [gain, setGain] = useState("")
    const [price, setPrice] = useState("")

    const updatingInfo = useCallback(async () => {
        try {
            if (connected && account && quid && usde && addressQD) {
                const setAddress = address ? address : account

                console.log(setAddress)

                await Promise.all([getDepositInfo(setAddress)])
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
        account, addressQD, connected, usde, quid, address])

    useEffect(() => {
        try {
            updatingInfo()
        } catch (error) {
            console.error("Some problem with sale's start function: ", error)
        }
    }, [resetAccounts, updatingInfo, connected, notifications])

    return (
        <div className={ address ? 'global-summary-root' : `summary-root`} >
            <div className="summary-section">
                {address ? <div className="summary-paragraph">Global</div> : null}
                <div className="summary-title">{address ? null : "My "}ETH pledged:</div>
                <div className="summary-value">
                    Ξ{connected && account ? numberWithCommas(parseFloat(Number(totalDeposited).toFixed(2))) : 0}
                </div>
                {address ? <div className="summary-strock"></div> : null}
            </div>
            <div className="summary-section">
                {address ? <div className="summary-paragraph">Global</div> : null}
                <div className="summary-title">{address ? null : "My "}$ owed:</div>
                <div className="summary-value">
                    ${connected && account ? numberWithCommas(parseFloat(Number(totalMinted).toFixed(2))) : 0}
                </div>
                {address ? <div className="summary-strock"></div> : null}
            </div>
            <div className="summary-section">   
                {address ? <div className="summary-paragraph">Global</div> : null}
                <div className="summary-title">{address ? null : "My "} ETH insured:</div>
                <div className="summary-value">
                    <span className="summary-value">${connected && account ? parseFloat(Number(price).toFixed(2)) : 0}</span>
                </div>
                {address ? <div className="summary-strock"></div> : null}
            </div>
            <div className="summary-section">
                {address ? <div className="summary-paragraph">Global</div> : null}
                <div className="summary-title">{address ? null : "My "} $ value of insured:</div>
                <div className="summary-value">
                    {connected && account ? parseFloat(Number(gain).toFixed(2)) : 0}
                </div>
                {address ? <div className="summary-strock"></div> : null}
            </div>
        </div>
    )
}
