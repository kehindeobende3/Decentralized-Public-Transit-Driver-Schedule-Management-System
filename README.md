# Decentralized Public Transit Driver Schedule Management System

A comprehensive blockchain-based system for managing public transit driver schedules, built on the Stacks blockchain using Clarity smart contracts.

## Overview

This system provides a decentralized solution for managing all aspects of public transit driver scheduling, from shift assignments to performance monitoring. The system ensures transparency, immutability, and fair management of driver schedules while maintaining operational efficiency.

## System Architecture

The system consists of five interconnected smart contracts:

### 1. Shift Assignment Contract (`shift-assignment.clar`)
- Manages bus driver work schedules and route assignments
- Handles shift creation, assignment, and modification
- Tracks driver availability and route coverage
- Ensures proper shift distribution among drivers

### 2. Overtime Calculation Contract (`overtime-calculation.clar`)
- Tracks extra hours worked beyond regular shifts
- Calculates overtime compensation based on predefined rates
- Manages overtime approval and payment processing
- Maintains historical overtime records

### 3. Sick Leave Coverage Contract (`sick-leave-coverage.clar`)
- Coordinates substitute drivers for absent personnel
- Manages sick leave requests and approvals
- Automatically finds and assigns replacement drivers
- Tracks sick leave usage and patterns

### 4. Break Scheduling Contract (`break-scheduling.clar`)
- Ensures drivers receive required rest periods
- Schedules mandatory breaks during shifts
- Monitors compliance with labor regulations
- Manages break coverage and replacements

### 5. Performance Monitoring Contract (`performance-monitoring.clar`)
- Tracks on-time performance metrics
- Records and manages customer complaints
- Maintains driver performance scores
- Generates performance reports and analytics

## Key Features

- **Decentralized Management**: No single point of failure or control
- **Transparent Operations**: All scheduling decisions are recorded on-chain
- **Automated Compliance**: Built-in labor law and regulation compliance
- **Fair Distribution**: Algorithmic shift and overtime distribution
- **Real-time Monitoring**: Live tracking of all system metrics
- **Immutable Records**: Permanent record of all scheduling decisions

## Data Structures

### Driver Profile
- Driver ID (unique identifier)
- Name and contact information
- License information and certifications
- Availability preferences
- Performance metrics
- Employment status

### Shift Information
- Shift ID and route assignment
- Start and end times
- Driver assignment
- Break schedules
- Status tracking

### Performance Metrics
- On-time performance percentage
- Customer satisfaction scores
- Complaint records
- Overtime hours
- Sick leave usage

## Contract Interactions

The contracts work together to provide a comprehensive management system:

1. **Shift Assignment** creates base schedules
2. **Break Scheduling** adds required rest periods
3. **Overtime Calculation** tracks extra hours
4. **Sick Leave Coverage** handles absences
5. **Performance Monitoring** tracks effectiveness

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm
- Stacks wallet for testing

### Installation

1. Clone the repository
2. Install dependencies: `npm install`
3. Run tests: `npm test`
4. Deploy contracts: `clarinet deploy`

### Testing

The system includes comprehensive tests for all contracts:
- Unit tests for individual contract functions
- Integration tests for contract interactions
- Performance and stress testing
- Compliance verification tests

## Usage Examples

### Creating a New Shift
\`\`\`clarity
(contract-call? .shift-assignment create-shift
u1 ;; route-id
u1234567890 ;; start-time
u1234571490 ;; end-time (1 hour later)
"Morning Route A")
\`\`\`

### Assigning a Driver
\`\`\`clarity
(contract-call? .shift-assignment assign-driver
u1 ;; shift-id
"driver123") ;; driver-id
\`\`\`

### Recording Performance
\`\`\`clarity
(contract-call? .performance-monitoring record-performance
"driver123"
u95 ;; on-time-percentage
u4) ;; customer-rating
\`\`\`

## Security Considerations

- All functions include proper authorization checks
- Input validation prevents malicious data
- State changes are atomic and consistent
- Access control ensures only authorized personnel can make changes

## Compliance Features

- Automatic enforcement of maximum work hours
- Mandatory break scheduling
- Overtime calculation according to labor laws
- Sick leave tracking and management
- Performance monitoring for safety compliance

## Future Enhancements

- Integration with GPS tracking systems
- Mobile app for drivers
- Automated route optimization
- Predictive analytics for scheduling
- Integration with payroll systems

## Contributing

Please read the contributing guidelines and submit pull requests for any improvements.

## License

This project is licensed under the MIT License.
