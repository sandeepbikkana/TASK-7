module.exports = ({ env }) => [
  "strapi::logger",
  "strapi::errors",

  {
    name: "strapi::cors",
    config: {
      enabled: true,
      origin: [
        "http://localhost:1337",
        env("FRONTEND_URL", "http://localhost:3000"),
      ],
      methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
      headers: ["*"],
    },
  },

  "strapi::security",
  "strapi::poweredBy",
  "strapi::query",
  "strapi::body",
  "strapi::session",
  "strapi::favicon",
  "strapi::public",
];
