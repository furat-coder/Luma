var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
import { ConflictException, Injectable, InternalServerErrorException, UnauthorizedException, } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { randomBytes, randomInt } from 'node:crypto';
import { db } from '../prisma/db.js';
let AuthService = class AuthService {
    async register(registerDto) {
        const email = registerDto.email.trim().toLowerCase();
        const username = registerDto.username.trim().toLowerCase();
        const displayName = registerDto.displayName.trim();
        const existingEmail = await db.orm.public.Account.first({
            email,
        });
        if (existingEmail) {
            throw new ConflictException('Email is already registered');
        }
        const existingUsername = await db.orm.public.Account.first({
            username,
        });
        if (existingUsername) {
            throw new ConflictException('Username is already taken');
        }
        try {
            const passwordHash = await bcrypt.hash(registerDto.password, 12);
            const account = await db.orm.public.Account.create({
                email,
                username,
                passwordHash,
                displayName,
                isVerified: false,
                isActive: true,
            });
            const verificationCode = randomInt(100000, 1000000).toString();
            const verificationExpiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();
            await db.orm.public.VerificationCode.create({
                code: verificationCode,
                type: 'email_verification',
                accountId: account.id,
                expiresAt: verificationExpiresAt,
            });
            return {
                success: true,
                message: 'Account created successfully',
                account: {
                    id: account.id,
                    email: account.email,
                    username: account.username,
                    displayName: account.displayName,
                    profileImage: account.profileImage,
                    isVerified: account.isVerified,
                    isActive: account.isActive,
                    createdAt: account.createdAt,
                },
                verification: {
                    code: verificationCode,
                    expiresAt: verificationExpiresAt,
                },
            };
        }
        catch (error) {
            console.error('Registration error:', error);
            throw new InternalServerErrorException('Unable to create account');
        }
    }
    async verifyEmail(emailInput, codeInput) {
        const email = emailInput.trim().toLowerCase();
        const code = codeInput.trim();
        const account = await db.orm.public.Account.first({
            email,
        });
        if (!account) {
            throw new UnauthorizedException('Account not found');
        }
        if (!account.isActive) {
            throw new UnauthorizedException('This account is inactive');
        }
        if (account.isVerified) {
            throw new ConflictException('Account is already verified');
        }
        const verification = await db.orm.public.VerificationCode.first({
            accountId: account.id,
            code,
            type: 'email_verification',
            usedAt: null,
        });
        if (!verification) {
            throw new UnauthorizedException('Invalid verification code');
        }
        const expiresAt = new Date(verification.expiresAt);
        if (expiresAt.getTime() <= Date.now()) {
            throw new UnauthorizedException('Verification code has expired');
        }
        try {
            await db.orm.public.VerificationCode.where({
                id: verification.id,
            }).update({
                usedAt: new Date().toISOString(),
            });
            await db.orm.public.Account.where({
                id: account.id,
            }).update({
                isVerified: true,
            });
            const updatedAccount = await db.orm.public.Account.first({
                id: account.id,
            });
            if (!updatedAccount) {
                throw new InternalServerErrorException('Account could not be loaded after verification');
            }
            const token = randomBytes(32).toString('hex');
            const sessionExpiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
            await db.orm.public.Session.create({
                token,
                accountId: updatedAccount.id,
                expiresAt: sessionExpiresAt,
            });
            return {
                success: true,
                message: 'Email verified successfully',
                session: {
                    token,
                    expiresAt: sessionExpiresAt,
                },
                account: {
                    id: updatedAccount.id,
                    email: updatedAccount.email,
                    username: updatedAccount.username,
                    displayName: updatedAccount.displayName,
                    profileImage: updatedAccount.profileImage,
                    isVerified: updatedAccount.isVerified,
                    isActive: updatedAccount.isActive,
                },
            };
        }
        catch (error) {
            console.error('Email verification error:', error);
            if (error instanceof InternalServerErrorException) {
                throw error;
            }
            throw new InternalServerErrorException('Unable to verify email');
        }
    }
    async resendVerification(emailInput) {
        const email = emailInput.trim().toLowerCase();
        const account = await db.orm.public.Account.first({
            email,
        });
        if (!account) {
            throw new UnauthorizedException('Account not found');
        }
        if (!account.isActive) {
            throw new UnauthorizedException('This account is inactive');
        }
        if (account.isVerified) {
            throw new ConflictException('Account is already verified');
        }
        try {
            const verificationCode = randomInt(100000, 1000000).toString();
            const verificationExpiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();
            const existingCodes = await db.orm.public.VerificationCode.where({
                accountId: account.id,
                type: 'email_verification',
                usedAt: null,
            }).all();
            for (const existingCode of existingCodes) {
                await db.orm.public.VerificationCode.where({
                    id: existingCode.id,
                }).update({
                    usedAt: new Date().toISOString(),
                });
            }
            await db.orm.public.VerificationCode.create({
                code: verificationCode,
                type: 'email_verification',
                accountId: account.id,
                expiresAt: verificationExpiresAt,
            });
            return {
                success: true,
                message: 'Verification code resent successfully',
                verification: {
                    code: verificationCode,
                    expiresAt: verificationExpiresAt,
                },
            };
        }
        catch (error) {
            console.error('Resend verification error:', error);
            throw new InternalServerErrorException('Unable to resend verification code');
        }
    }
    async login(loginDto) {
        const identifier = loginDto.identifier.trim().toLowerCase();
        let account = await db.orm.public.Account.first({
            email: identifier,
        });
        if (!account) {
            account = await db.orm.public.Account.first({
                username: identifier,
            });
        }
        if (!account) {
            throw new UnauthorizedException('Invalid email/username or password');
        }
        if (!account.isActive) {
            throw new UnauthorizedException('This account is inactive');
        }
        const passwordMatches = await bcrypt.compare(loginDto.password, account.passwordHash);
        if (!passwordMatches) {
            throw new UnauthorizedException('Invalid email/username or password');
        }
        try {
            const token = randomBytes(32).toString('hex');
            const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
            await db.orm.public.Session.create({
                token,
                accountId: account.id,
                expiresAt,
            });
            return {
                success: true,
                message: 'Login successful',
                session: {
                    token,
                    expiresAt,
                },
                account: {
                    id: account.id,
                    email: account.email,
                    username: account.username,
                    displayName: account.displayName,
                    profileImage: account.profileImage,
                    isVerified: account.isVerified,
                    isActive: account.isActive,
                },
            };
        }
        catch (error) {
            console.error('Login error:', error);
            throw new InternalServerErrorException('Unable to create login session');
        }
    }
    async logout(token) {
        const session = await db.orm.public.Session.first({
            token,
        });
        if (!session) {
            return {
                success: true,
                message: 'Already logged out',
            };
        }
        await db.orm.public.Session.where({
            id: session.id,
        }).delete();
        return {
            success: true,
            message: 'Logout successful',
        };
    }
};
AuthService = __decorate([
    Injectable()
], AuthService);
export { AuthService };
//# sourceMappingURL=auth.service.js.map