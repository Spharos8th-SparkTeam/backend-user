package com.spark.user.terms.dto.response;

import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.UUID;

@Getter
@Builder
public class TermsResponseDto {

    private final UUID termsId;
    private final String termsCode;
    private final String versionLabel;
    private final String title;
    private final String contentUrl;
    private final Boolean required;
    private final LocalDateTime effectiveAt;
}
