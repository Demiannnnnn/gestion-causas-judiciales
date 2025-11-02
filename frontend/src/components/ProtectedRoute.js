import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const ProtectedRoute = ({ children }) => {
    const { isLoggedIn } = useAuth();

    if (!isLoggedIn) {
        // Si el usuario no está logueado, redirigir a la página de login
        return <Navigate to="/login" />;
    }

    return children; // Si está logueado, renderizar el componente hijo (la página solicitada)
};

export default ProtectedRoute;
