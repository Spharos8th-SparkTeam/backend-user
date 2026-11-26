package com.spark.user.common.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SwaggerConfig {

    @Bean
    public OpenAPI userServiceOpenApi() {
        return new OpenAPI()
                .info(new Info()
                        .title("user-service")
                        .description("회원 서비스 API. 경로는 API 정의서를 따른다. 현재 응답은 저장하지 않는 껍데기다.")
                        .version("v1"));
    }
}
