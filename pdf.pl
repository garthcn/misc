use PDF::OCR::Thorough;

my $abs_pdf = $filename;
$filename = "~/Documents/GRE/3000.pdf";

my $p = new PDF::OCR::Thorough($abs_pdf);

my $text = $p->get_text;

print $text;
