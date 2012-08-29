{
   s/^[:blank:]*Source/#Source/
   s/^[:blank:]*Patch/#Patch/
   /^[:blank:]*Release/a  Source: src.tar.gz
}

1,/^[:blank:]*%prep/{
    /^[:blank:]*%prep/a \%setup -q -n src \n
    p
}

/^[:blank:]*%build/,/^[:blank:]*%install/{
    p
}

/^[:blank:]*%install/,${
    /[:blank:]*%install/d
    p
}
