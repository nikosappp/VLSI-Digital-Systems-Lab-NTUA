import os
import random

N = 32
INPUT_FILE = "C:/VLSI/lab5-6/input_image.txt"
OUTPUT_FILE = "C:/VLSI/lab5-6/expected_output.txt"

# Generate Random Input Image
def generate_test_image(filename, size):
    """Creates a random N x N image in 8-bit binary string format."""
    print(f"Generating random {size}x{size} input image: {filename}...")
    with open(filename, 'w') as f:
        for _ in range(size * size):
            val = random.randint(0, 255)
            # Format as 8-bit binary string with leading zeros
            f.write(f"{val:08b}\n")

# Read Image into 2D Array
def read_image(filename, size):
    print(f"Reading input image: {filename}...")
    img = [[0 for _ in range(size)] for _ in range(size)]
    
    with open(filename, 'r') as f:
        for r in range(size):
            for c in range(size):
                line = f.readline().strip()
                if line:
                    img[r][c] = int(line, 2) # Convert binary string to integer
    return img

# Simulate Hardware Debayering
def calculate_debayering(img, size):
    print("Calculating expected hardware outputs...")
    output_data = []
    
    for r in range(size):
        for c in range(size):
            
            # Extract 3x3 Window
            # Replicates VHDL edge-case zero-padding perfectly
            m11 = img[r-1][c-1] if (r > 0 and c > 0) else 0
            m12 = img[r-1][c]   if (r > 0) else 0
            m13 = img[r-1][c+1] if (r > 0 and c < size - 1) else 0

            m21 = img[r][c-1]   if (c > 0) else 0
            m22 = img[r][c]
            m23 = img[r][c+1]   if (c < size - 1) else 0

            m31 = img[r+1][c-1] if (r < size - 1 and c > 0) else 0
            m32 = img[r+1][c]   if (r < size - 1) else 0
            m33 = img[r+1][c+1] if (r < size - 1 and c < size - 1) else 0

            # Determine LSBs for Bayer Pattern
            row_lsb = r % 2
            col_lsb = c % 2

            # Apply math exactly like the VHDL datapath 
            # (Integer division '//' perfectly mirrors VHDL bit-shifting)
            if row_lsb == 1 and col_lsb == 1:
                # ctrl "00": Green (Red-Green row)
                R = (m21 + m23) // 2
                G = m22
                B = (m12 + m32) // 2
                
            elif row_lsb == 0 and col_lsb == 0:
                # ctrl "01": Green (Green-Blue row)
                R = (m12 + m32) // 2
                G = m22
                B = (m21 + m23) // 2
                
            elif row_lsb == 1 and col_lsb == 0:
                # ctrl "10": Red
                R = m22
                G = (m12 + m21 + m23 + m32) // 4
                B = (m11 + m13 + m31 + m33) // 4
                
            elif row_lsb == 0 and col_lsb == 1:
                # ctrl "11": Blue
                R = (m11 + m13 + m31 + m33) // 4
                G = (m12 + m21 + m23 + m32) // 4
                B = m22
                
            else:
                R, G, B = 0, 0, 0

            output_data.append((R, G, B))
            
    return output_data

# Write Expected Output File
def write_output(filename, data):
    print(f"Writing expected output: {filename}...")
    with open(filename, 'w') as f:
        for R, G, B in data:
            # Write 3 space-separated binary strings per line
            f.write(f"{R:08b} {G:08b} {B:08b}\n")
    print("Done!")

# Main Execution
if __name__ == "__main__":
    # Create a random input file
    generate_test_image(INPUT_FILE, N)
    
    # Read it back
    img_array = read_image(INPUT_FILE, N)
    
    # Process it mathematically
    expected_rgb = calculate_debayering(img_array, N)
    
    # Save the expected answers
    write_output(OUTPUT_FILE, expected_rgb)