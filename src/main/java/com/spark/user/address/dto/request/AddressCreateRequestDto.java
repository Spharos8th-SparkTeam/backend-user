package com.spark.user.address.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class AddressCreateRequestDto {

    @NotBlank
    @Size(max = 100)
    private String recipientName;

    @NotBlank
    @Size(max = 30)
    private String phoneNumber;

    @NotBlank
    @Size(max = 255)
    private String addressLine;

    @NotBlank
    @Size(max = 150)
    private String addressDetail;

    @NotBlank
    @Size(max = 20)
    private String postcode;

    @NotNull
    private Boolean defaultAddress;
}
