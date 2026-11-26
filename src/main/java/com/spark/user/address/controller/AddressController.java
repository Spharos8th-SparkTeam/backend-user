package com.spark.user.address.controller;

import com.spark.user.address.dto.request.AddressCreateRequestDto;
import com.spark.user.address.dto.response.AddressResponseDto;
import com.spark.user.address.service.AddressService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users/{userId}/address")
@RequiredArgsConstructor
@Tag(name = "배송지", description = "회원 배송지")
public class AddressController {

    private final AddressService addressService;

    @GetMapping
    @Operation(summary = "배송지 조회", description = "데이터는 조회하지 않는다.")
    public AddressResponseDto getAddress(@PathVariable UUID userId) {
        return addressService.getAddress(userId);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @Operation(summary = "배송지 등록", description = "데이터는 저장하지 않는다.")
    public AddressResponseDto createAddress(
            @PathVariable UUID userId,
            @Valid @RequestBody AddressCreateRequestDto request) {
        return addressService.createAddress(userId, request);
    }
}
