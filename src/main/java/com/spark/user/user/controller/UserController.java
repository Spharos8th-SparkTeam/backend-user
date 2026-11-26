package com.spark.user.user.controller;

import com.spark.user.user.dto.request.UserUpdateRequestDto;
import com.spark.user.user.dto.response.UserResponseDto;
import com.spark.user.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/users")
@RequiredArgsConstructor
@Tag(name = "회원", description = "회원 프로필")
public class UserController {

    private final UserService userService;

    @GetMapping("/{userId}")
    @Operation(summary = "회원 조회", description = "데이터는 조회하지 않는다. userId는 회원 UUID다.")
    public UserResponseDto getUser(@PathVariable UUID userId) {
        return userService.getUser(userId);
    }

    @PatchMapping("/{userId}")
    @Operation(summary = "회원 수정", description = "데이터는 저장하지 않는다.")
    public UserResponseDto updateUser(
            @PathVariable UUID userId,
            @Valid @RequestBody UserUpdateRequestDto request) {
        return userService.updateUser(userId, request);
    }

    @DeleteMapping("/{userId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @Operation(summary = "회원 탈퇴", description = "데이터는 삭제하지 않는다.")
    public void deleteUser(@PathVariable UUID userId) {
        userService.deleteUser(userId);
    }
}
