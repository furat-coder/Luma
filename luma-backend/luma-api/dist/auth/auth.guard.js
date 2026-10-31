var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
import { Injectable, UnauthorizedException, } from '@nestjs/common';
import { db } from '../prisma/db.js';
let AuthGuard = class AuthGuard {
    async canActivate(context) {
        const request = context.switchToHttp().getRequest();
        const authorization = request.headers.authorization;
        if (!authorization) {
            throw new UnauthorizedException('Missing authorization token');
        }
        const [scheme, token] = authorization.split(' ');
        if (scheme !== 'Bearer' || !token) {
            throw new UnauthorizedException('Invalid authorization format');
        }
        const session = await db.orm.public.Session.first({
            token,
        });
        if (!session) {
            throw new UnauthorizedException('Invalid or expired session');
        }
        const expiresAt = new Date(session.expiresAt);
        if (expiresAt.getTime() <= Date.now()) {
            throw new UnauthorizedException('Session has expired');
        }
        const account = await db.orm.public.Account.first({
            id: session.accountId,
        });
        if (!account || !account.isActive) {
            throw new UnauthorizedException('Account is unavailable');
        }
        request.account = account;
        request.session = session;
        return true;
    }
};
AuthGuard = __decorate([
    Injectable()
], AuthGuard);
export { AuthGuard };
//# sourceMappingURL=auth.guard.js.map