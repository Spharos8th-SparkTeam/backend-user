package com.spark.user.terms.controller;

import com.spark.user.terms.dto.response.TermsResponseDto;
import com.spark.user.terms.service.TermsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/terms")
@RequiredArgsConstructor
@Tag(name = "약관", description = "약관 기준정보")
public class TermsController {

    private final TermsService termsService;

    @GetMapping
    @Operation(summary = "약관 목록 조회", description = "기준정보는 아직 조회하지 않는다.")
    public List<TermsResponseDto> getTerms() {
        return termsService.getTerms();
    }
}
