import argparse
import os
import pathlib
import sys

def generate_qrc_v1(root, output_file):
	root_path = pathlib.Path(root).resolve(strict=True)
	output_path = pathlib.Path(output_file).resolve()
	output_path.parent.mkdir(parents=True, exist_ok=True)

	indent_lvl = 0

	def create_line(line_str):
		nonlocal indent_lvl
		return (indent_lvl * '\t') + line_str + os.linesep
	
	def create_block(directory_path, prefixpath):
		nonlocal indent_lvl, output_path
		block = create_line('<qresource prefix="{}">'.format(prefixpath))
		indent_lvl += 1
		for file_path in [x for x in directory_path.iterdir() if x.is_file()]:
			filename = file_path.name
			relative_path = os.path.relpath(file_path, output_path.parent)
			block += create_line('<file alias="{}">{}</file>'.format(filename, relative_path))
		indent_lvl -= 1
		block += create_line('</qresource>')
		return block

	def create_directory_block(directory_path, prefixpath):
		nonlocal indent_lvl
		block = create_block(directory_path, prefixpath)
		for inner_directory_path in [x for x in directory_path.iterdir() if x.is_dir()]:
			new_prefixpath = prefixpath + inner_directory_path.stem + '/'
			indent_lvl += 1
			block += create_directory_block(inner_directory_path, new_prefixpath)
			indent_lvl -= 1
		return block
	
	with open(output_file, 'w') as f:
		f.write(create_line('<!DOCTYPE RCC><RCC version="1.0">'))
		indent_lvl += 1
		f.write(create_directory_block(root_path, '/'))
		indent_lvl -= 1
		f.write(create_line('</RCC>'))

def assert_python_version(major, minor = 0, patch = 0):
	assert sys.version_info >= (major, minor, patch)

def parse_arguments():
	parser = argparse.ArgumentParser()
	parser.add_argument('root', help='Root directory of resources', type=str)
	parser.add_argument('-o', '--output_file', help='Where to genrate the qrc file', type=str, required=True)
	return parser.parse_args()


def main():
	assert_python_version(3, 7, 0)
	args = parse_arguments()

	generate_qrc_v1(args.root, args.output_file)

if __name__ == "__main__":
	main()