function bounds = q5c_wilson_interval(failures, count)
%Q5C_WILSON_INTERVAL Two-sided 95 percent Wilson interval for packet failures.
arguments
    failures (1,1) double {mustBeInteger,mustBeNonnegative}
    count (1,1) double {mustBeInteger,mustBePositive}
end
assert(failures<=count,'q5c:Counts','Failures cannot exceed trials.');
z=1.959963984540054;
p=failures/count;
center=(p+z^2/(2*count))/(1+z^2/count);
half=z*sqrt(p*(1-p)/count+z^2/(4*count^2))/(1+z^2/count);
bounds=[max(0,center-half) min(1,center+half)];
end
