package com.spark.user;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.web.client.RestClient;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class UserServiceApplicationTests {

    @LocalServerPort
    private int port;

    @Test
    void openApiMatchesApiDefinition() {
        String body = RestClient.create()
                .get()
                .uri("http://127.0.0.1:" + port + "/v3/api-docs")
                .retrieve()
                .body(String.class);

        assertThat(body).contains(
                "/api/v1/email/verifications",
                "/api/v1/auth/signup",
                "/api/v1/auth/login",
                "/api/v1/auth/social/signup",
                "/api/v1/auth/social/login",
                "/api/v1/auth/logout",
                "/api/v1/auth/password/reset",
                "/api/v1/auth/password",
                "/api/v1/users/{userId}",
                "/api/v1/users/{userId}/address",
                "/api/v1/users/{userId}/account",
                "/api/v1/terms",
                "/api/v1/admin/{userId}");
        assertThat(body).doesNotContain("/api/v1/members");
        assertThat(body).doesNotContain("profile-cards");
        assertThat(body).doesNotContain("/reports");
        assertThat(body).doesNotContain("membership-plans");
    }
}
