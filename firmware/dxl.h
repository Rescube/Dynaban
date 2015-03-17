#ifndef DXL_H
#define DXL_H

// Protocol definition
#define DXL_BROADCAST   0xFE

// Size limit for a buffer containing a dynamixel packet
#define DXL_BUFFER_SIZE 300

// Maximum parameters in a packet
#define DXL_MAX_PARAMS 140

// Address of dynamixel first RAM register
#define DXL_RAM_BEGIN   0x18

// Model number
#define DXL_MODEL       0x136

#define DXL_PING        0x01
#define DXL_READ_DATA   0x02
#define DXL_WRITE_DATA  0x03
#define DXL_REG_WRITE   0x04
#define DXL_ACTION      0x05
#define DXL_RESET       0x06
#define DXL_SYNC_WRITE  0x83
#define DXL_NO_ERROR    0x0

typedef unsigned char ui8;

/**
 * A dynamixel packet
 */
struct dxl_packet {
    ui8 id;
    union {
        ui8 instruction;
        ui8 error;
    };
    ui8 parameter_nb;
    ui8 parameters[DXL_MAX_PARAMS];
    bool process;
    bool answer;
    ui8 dxl_state;
};

// HAL to implement
unsigned int dxl_data_available();
ui8 dxl_data_byte();
void dxl_send(ui8 *buffer, int n);
bool dxl_sending();

// Call init to init the dynamixel structures, and then tick it periodically
void dxl_init();
bool dxl_tick();

bool dxl_process();
void dxl_init_regs();
void dxl_push_byte(ui8 b);
int dxl_write(ui8 *buffer);

void dxl_packet_init(volatile struct dxl_packet *packet);
void dxl_packet_push_byte(volatile struct dxl_packet *packet, ui8 b);
int dxl_write_packet(volatile struct dxl_packet *packet, ui8 *buffer);
ui8 dxl_compute_checksum(volatile struct dxl_packet *packet);

struct dxl_eeprom {
    unsigned short modelNumber;             // 0x00
    unsigned char firmwareVersion;          // 0x02
    unsigned char id;                       // 0x03
    unsigned char baudrate;                 // 0x04
    unsigned char returnDelay;              // 0x05
    unsigned short cwLimit;                 // 0x06
    unsigned short ccwLimit;                // 0x08
    unsigned char _padding;                 // 0x0a
    unsigned char temperatureLimit;         // 0x0b
    unsigned char lowestVoltage;            // 0x0c
    unsigned char highestVoltage;           // 0x0d
    unsigned short maxTorque;               // 0x0e
    unsigned char returnStatus;             // 0x10
    unsigned char alarmLed;                 // 0x11
    unsigned char alarmShutdown;            // 0x12
    unsigned char _padding6;                // 0x13
    unsigned short multiTurnOffset;         // 0x14
    unsigned char resolutionDivider;        // 0x16
    volatile unsigned char _padding2;       // 0x17
} __attribute__((packed)); // Size: 24

struct dxl_ram {
    unsigned char torqueEnable;             // 0x18
    unsigned char led;                      // 0x19
    unsigned char servoKd;                  // 0x1a
    unsigned char servoKi;                  // 0x1b
    unsigned char servoKp;                  // 0x1c
    unsigned char _padding7;                // 0x1d
    unsigned short goalPosition;            // 0x1e
    unsigned short movingSpeed;             // 0x20
    unsigned short torqueLimit;             // 0x22
    unsigned short presentPosition;         // 0x24
    unsigned short presentSpeed;            // 0x26
    unsigned short presentLoad;             // 0x28
    unsigned char presentVoltage;           // 0x2a
    unsigned char presentTemperature;       // 0x2b
    unsigned char registeredInstruction;    // 0x2c
    unsigned char _padding3;                // 0x2d
    unsigned char moving;                   // 0x2e
    unsigned char lock;                     // 0x2f
    unsigned short punch;                   // 0x30
    unsigned char _padding4[18];            // 0x32
    unsigned short current;                 // 0x44
    unsigned char torqueMode;               // 0x46
    unsigned short goalTorque;              // 0x47 ---> Some padding here would not hurt !
    unsigned char goalAcceleration;         // 0x49
    unsigned char poly1Size;                // 0x4A
    float         poly1[5];                 //[4B,4C,4D,4E],
                                            //[4F,50,51,52],
                                            //[53,54,55,56],
                                            //[57,58,59,5A],
                                            //[5B,5C,5D,5E]

} __attribute__((packed));

struct dxl_registers
{
    volatile struct dxl_eeprom eeprom;
    volatile struct dxl_ram ram;
    volatile char eeprom_dirty;
} __attribute__((packed));

// Dynamixel registers
extern struct dxl_registers dxl_regs;

// Dynamixel packets
extern struct dxl_packet    dxl_packet;

#endif // DXL_H
