package com.spark.user.address.service;

import com.spark.user.address.dto.request.AddressCreateRequestDto;
import com.spark.user.address.dto.response.AddressResponseDto;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class AddressService {

    // TODO: 배송지 조회 구현
    public AddressResponseDto getAddress(UUID userId) {
        return AddressResponseDto.builder()
                .userId(userId)
                .build();
    }

    // TODO: 배송지 저장 구현
    public AddressResponseDto createAddress(UUID userId, AddressCreateRequestDto request) {
        return AddressResponseDto.builder()
                .addressId(UUID.randomUUID())
                .userId(userId)
                .recipientName(request.getRecipientName())
                .phoneNumber(request.getPhoneNumber())
                .addressLine(request.getAddressLine())
                .addressDetail(request.getAddressDetail())
                .postcode(request.getPostcode())
                .defaultAddress(request.getDefaultAddress())
                .build();
    }
}
