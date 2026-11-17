package com.example.heatwaveadvisory;

import com.example.heatwaveadvisory.document.UserDocument;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class ResetAdminPassword implements ApplicationRunner {

    private final MongoTemplate mongoTemplate;

    public ResetAdminPassword(MongoTemplate mongoTemplate) {
        this.mongoTemplate = mongoTemplate;
    }

    @Override
    public void run(ApplicationArguments args) {
        String password = System.getenv("ADMIN_RESET_PASSWORD");

        if (password == null || password.length() < 10) {
            System.out.println("ADMIN PASSWORD RESET SKIPPED: Set ADMIN_RESET_PASSWORD (minimum 10 characters).");
            return;
        }

        String hash = new BCryptPasswordEncoder(12).encode(password);

        var result = mongoTemplate.updateFirst(
            Query.query(Criteria.where("username").is("admin")),
            new Update().set("passwordHash", hash),
            UserDocument.class
        );

        if (result.getMatchedCount() == 0) {
            System.out.println("ADMIN PASSWORD RESET FAILED: admin user was not found.");
        } else {
            System.out.println("ADMIN PASSWORD RESET SUCCESSFUL. Updated documents: "
                + result.getModifiedCount());
        }
    }
}