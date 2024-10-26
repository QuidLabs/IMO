import React from 'react'
import { Swiper, SwiperSlide } from 'swiper/react'

import { MintBar } from '../../components/MintBar'
import { DepositeBar } from '../../components/DepositeBar'

import { Mint } from '../../components/Mint'

import './MaintPage.scss';
const MaintPage = () => {
  return (
    <React.Fragment>
      <Swiper
        /*onSwiper={(swiper) => setSwiperRef(swiper)}*/
        slidesPerView={1}
        direction={'vertical'}
        className="main-carousel"
        allowTouchMove={false}
      >
        <SwiperSlide className="main-slide">
          <div className="main-side">
            <MintBar />
          </div>
          <div className="main-content">
            <div className="main-mintContainer">
              <Mint />
            </div>
          </div>
          <div className="main-fakeCol" />
          <div className="main-side">
            <DepositeBar />
          </div>
        </SwiperSlide>
      </Swiper>
    </React.Fragment>
  );
};

export default MaintPage;
