package com.spark.user.auth.dto.request;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class TermsAgreementRequestDto {

    @NotNull
    private UUID termsId;

    @NotNull
    private Boolean agreed;
}
