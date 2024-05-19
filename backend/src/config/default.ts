export default () => ({
    AWS_ACCESS_KEY_ID: process.env.AWS_ACCESS_KEY_ID,
    AWS_SECRET_ACCESS_KEY: process.env.AWS_SECRET_ACCESS_KEY,
    S3_REGION: process.env.S3_REGION || 'eu-west-3',
    S3_BUCKET: process.env.S3_BUCKET,
});