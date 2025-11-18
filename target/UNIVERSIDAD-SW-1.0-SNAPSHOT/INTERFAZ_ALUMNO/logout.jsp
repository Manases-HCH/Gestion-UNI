<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Invalidate the current session
    session.invalidate();

    // Redirect to plantilla.jsp after invalidating the session
    // It's good practice to use request.getContextPath() for portability
    response.sendRedirect(request.getContextPath() + "/Plataforma.jsp");
%>