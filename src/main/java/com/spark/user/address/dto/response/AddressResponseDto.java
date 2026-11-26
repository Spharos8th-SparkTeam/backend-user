package com.spark.user.address.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.util.UUID;

@Getter
@Builder
public class AddressResponseDto {

    private final UUID addressId;
    private final UUID userId;
    private final String recipientName;
    private final String phoneNumber;
    private final String addressLine;
    private final String addressDetail;
    private final String postcode;
    private final Boolean defaultAddress;
}
