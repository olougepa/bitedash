<?php
/**
 * @OA\Info(title="Bitedash API", version="1.0.0", description="Bitedash backend API")
 *
 * @OA\SecurityScheme(
 *   securityScheme="bearerAuth",
 *   type="http",
 *   scheme="bearer",
 *   bearerFormat="JWT"
 * )
 *
 * @OA\Schema(
 *   schema="LoginRequest",
 *   type="object",
 *   @OA\Property(property="email", type="string"),
 *   @OA\Property(property="password", type="string")
 * )
 *
 * @OA\Schema(
 *   schema="AuthResponse",
 *   type="object",
 *   @OA\Property(property="access_token", type="string"),
 *   @OA\Property(property="refresh_token", type="string"),
 *   @OA\Property(property="expires_in", type="integer")
 * )
 *
 * @OA\Schema(
 *   schema="User",
 *   type="object",
 *   @OA\Property(property="id", type="integer"),
 *   @OA\Property(property="email", type="string"),
 *   @OA\Property(property="full_name", type="string")
 * )
 */
// marker file for swagger-php

/**
 * @OA\PathItem(
 *   path="/auth/login",
 *   @OA\Post(
 *     summary="Login",
 *     @OA\RequestBody(@OA\MediaType(mediaType="application/json", @OA\Schema(ref="#/components/schemas/LoginRequest"))),
 *     @OA\Response(response=200, description="OK", @OA\MediaType(mediaType="application/json", @OA\Schema(ref="#/components/schemas/AuthResponse")))
 *   )
 * )
 *
 * @OA\PathItem(
 *   path="/auth/register",
 *   @OA\Post(summary="Register user")
 * )
 *
 * @OA\PathItem(
 *   path="/auth/refresh",
 *   @OA\Post(summary="Refresh token", @OA\RequestBody(@OA\MediaType(mediaType="application/json")))
 * )
 *
 * @OA\PathItem(
 *   path="/auth/profile",
 *   @OA\Get(summary="Get profile", security={{"bearerAuth":{}}}, @OA\Response(response=200, description="User"))
 * )
 *
 * @OA\PathItem(
 *   path="/orders",
 *   @OA\Get(summary="List orders"),
 *   @OA\Post(summary="Create order")
 * )
 *
 * @OA\PathItem(
 *   path="/notifications",
 *   @OA\Get(summary="List notifications")
 * )
 */
