import { useEffect, useRef } from "react"
import { Swiper, SwiperSlide } from "swiper/react"
import { useAppContext } from "../../contexts/AppContext"

import { DepositBar } from "../DepositBar"
import { MintBar } from "../MintBar"

import 'swiper/css'
import 'swiper/css/navigation'

import "./Styles/Slider.scss"

export function SideBar() {
    const { chooseButton, swipeStatus } = useAppContext()

    const swiperRef = useRef(null)

    useEffect(() => {        
        if(chooseButton.current === "MINT" || chooseButton.current == null )swiperRef.current.slideTo(0)
        else swiperRef.current.slideTo(1)
    }, [chooseButton, swipeStatus])

    return (
        <Swiper
            className="mySwiper"
            slidesPerView={1}
            initialSlide={0}
            onSwiper={(swiper) => {
                swiperRef.current = swiper
            }}
        >
            <SwiperSlide>
                <MintBar />
            </SwiperSlide>
            <SwiperSlide>
                <DepositBar />
            </SwiperSlide>
        </Swiper>
    )
}
