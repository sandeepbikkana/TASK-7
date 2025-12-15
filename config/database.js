// module.exports = ({ env }) => ({
//   connection: {
//     client: 'postgres',
//     connection: {
//       host: env('DATABASE_HOST', 'postgres'),
//       port: env.int('DATABASE_PORT', 5432),
//       database: env('DATABASE_NAME', 'postgres'),
//       user: env('DATABASE_USERNAME', 'postgres'),
//       password: env('DATABASE_PASSWORD', 'postgres'),

//       ssl: false,   // IMPORTANT: DISABLE SSL FOR LOCAL DEVELOPMENT
//     },
//   },
// });


module.exports = ({ env }) => ({
  connection: {
    client: 'postgres',
    connection: {
      host: env('DATABASE_HOST'),
      port: env('DATABASE_PORT'),
      database: env('DATABASE_NAME'),
      user: env('DATABASE_USERNAME'),
      password: env('DATABASE_PASSWORD'),
      ssl: {
        rejectUnauthorized: false,
      },
    },
    debug: false,
  },
});
