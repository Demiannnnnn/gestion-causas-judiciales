import React, { createContext, useState, useContext, useMemo } from 'react';
import { getUserRole } from '../utils/auth';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
    const [token, setToken] = useState(localStorage.getItem('token'));

    const login = (newToken) => {
        localStorage.setItem('token', newToken);
        setToken(newToken);
    };

    const logout = () => {
        localStorage.removeItem('token');
        setToken(null);
    };

    const userRole = useMemo(() => getUserRole(token), [token]);

    // El valor que proveemos a los componentes hijos
    const value = {
        token,
        isLoggedIn: !!token,
        userRole,
        login,
        logout,
    };

    return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

// Hook personalizado para usar el contexto fácilmente
export const useAuth = () => {
    return useContext(AuthContext);
};
