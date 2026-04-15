fid = fopen('Era5/Postprocess/era5_report.tex','w');

fprintf(fid, '\\section{City-Level Results}\n');

for i = 1:length(results_all)

    city = results_all(i).city;

    fprintf(fid, '\\subsection{%s}\n', city);

    fprintf(fid, '\\subsubsection{Annual MIL-310 Statistics}\n');
    fprintf(fid, '\\pgfplotstabletypeset[col sep=comma]{%s/MIL310_summary_%s_year.csv}\n', city, city);

    fprintf(fid, '\\subsubsection{Monthly Statistics (1-hour)}\n');
    fprintf(fid, '\\pgfplotstabletypeset[col sep=comma]{%s/MIL310_summary_%s_month_1hr.csv}\n', city, city);

    fprintf(fid, '\\subsubsection{Monthly Statistics (24-hour)}\n');
    fprintf(fid, '\\pgfplotstabletypeset[col sep=comma]{%s/MIL310_summary_%s_month_24hr.csv}\n', city, city);

    fprintf(fid, '\\begin{figure}[h!]\n');
    fprintf(fid, '\\centering\n');
    fprintf(fid, '\\includegraphics[width=0.75\\textwidth]{%s/kernel_density_full.png}\n', city);
    fprintf(fid, '\\caption{Kernel Density of t2m for %s}\n', city);
    fprintf(fid, '\\end{figure}\n');

end

fclose(fid);