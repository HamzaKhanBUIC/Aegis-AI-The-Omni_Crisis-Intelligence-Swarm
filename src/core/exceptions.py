"""
src/core/exceptions.py
Custom exceptions for the Aegis-Omni System.
"""

class AegisBaseException(Exception):
    """Base exception for Aegis-Omni system."""
    pass

class SignalValidationError(AegisBaseException):
    """Raised when an incoming crisis signal fails zero-trust validation."""
    pass

class EngineExecutionError(AegisBaseException):
    """Raised when the LangGraph engine fails to execute a node."""
    pass
