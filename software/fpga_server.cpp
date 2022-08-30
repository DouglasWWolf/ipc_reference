//==========================================================================================================
// demo_server.h - Defines a TCP command-line server
//==========================================================================================================
#include "globals.h"
using namespace std;


//==========================================================================================================
// handle_command() - This gets called every time a command arrives on the server
//==========================================================================================================
void CDemoServer::handle_command()
{
    printf("Rcvd: \"%s\"\n", m_raw_line.c_str());
    AXI_IPC.post(m_raw_line);
}
//==========================================================================================================


//==========================================================================================================
// handle_add() - Adds two numbers and reports the result
//==========================================================================================================
bool CDemoServer::handle_add()
{
    int v1, v2;

    // Fetch the command parameters as integers
    if (!m_line.get_next(&v1)) return fail_syntax();
    if (!m_line.get_next(&v2)) return fail_syntax();

    // Perform the operation
    int result = v1 + v2;

    // Report the result to the caller
    return pass("%i", result);
}
//==========================================================================================================



//==========================================================================================================
// handle_sub() - Subtracts two integers and reports the result
//==========================================================================================================
bool CDemoServer::handle_sub()
{
    int v1, v2;

    // Fetch the command parameters as integers
    if (!m_line.get_next(&v1)) return fail_syntax();
    if (!m_line.get_next(&v2)) return fail_syntax();

    m_line.get_next(&v1);
    m_line.get_next(&v2);

    // Perform the operation
    int result = v1 - v2;

    // Report the result to the caller
    return pass("%i", result);
}
//==========================================================================================================



//==========================================================================================================
// handle_mul() - multiples two floating-point numbers and reports the result
//==========================================================================================================
bool CDemoServer::handle_mul()
{
    double v1, v2;

    // Fetch the command parameters as integers
    if (!m_line.get_next(&v1)) return fail_syntax();
    if (!m_line.get_next(&v2)) return fail_syntax();
    
    // Perform the operation
    double result = v1 * v2;

    // Report the result to the caller
    return pass("%1.4lf", result);
}
//==========================================================================================================


//==========================================================================================================
// handle_help() - Sends help text to the client
//
// Notes:  Like all list-style data, help-text should always begin with a space so that automated clients
//         know when they've reached the end of the list
//==========================================================================================================
bool CDemoServer::handle_help()
{
    send(" add <integer> <integer>\r\n");
    send(" sub <integer> <integer>\r\n");
    send(" mul <float> <float>\r\n");

    return pass();
}
//==========================================================================================================









