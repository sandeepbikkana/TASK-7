const fs = require("fs");
const path = require("path");

module.exports = ({ env }) => {
  // Auto-create public/uploads if missing
  const uploadDir = path.join(__dirname, "..", "public", "uploads");

  if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
  }

  return {
    upload: {
      config: {
        provider: "local",
        providerOptions: {
          sizeLimit: 10000000, // 10MB
        },
      },
    },

    "users-permissions": {
      config: {
        jwtSecret: env("JWT_SECRET", "local-dev-secret"),
      },
    },
  };
};
