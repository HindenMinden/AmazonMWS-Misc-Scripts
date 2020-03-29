#!/usr/bin/perl

use strict;
use warnings;
use File::Slurp qw(slurp);
use Amazon::MWS::Client;
use Try::Tiny;
use XML::Simple;

my $mws_marketplace_id = 'x',
my $mws_merchant_id    = 'x',
my $mws_secret_key     = 'x';
my $mws_access_key     = 'x';

my $amz = Amazon::MWS::Client->new(
    access_key_id  => $mws_access_key,
    secret_key     => $mws_secret_key,
    merchant_id    => $mws_merchant_id,
    marketplace_id => $mws_access_key,
);

my $data  = slurp(@ARGV);
my @gtins = split("\n", $data);

my %ranks;
for my $gtin (@gtins)
{
    $gtin =~ s/\s+//g;
    $gtin =~ s/\-//g;
    next unless $gtin;

    my $r;
    try {
        $r = $amz->ListMatchingProducts(
            MarketplaceId => [$mws_marketplace_id],
            Query => $gtin,
        );
    } catch {
        warn $_;
    };

    next unless $r;
    $r = $r->[0] if ref($r) eq 'ARRAY';
    my $asin = $r->{Identifiers}{MarketplaceASIN}{ASIN};
    unless ($asin)
    {
        warn "Can't find ASIN for GTIN $gtin";
        next;
    }

    my $sales_rank;
    my $r_obj = $r->{SalesRankings}{SalesRank};
    if (ref $r_obj eq 'ARRAY')
    {
        $sales_rank = $r->{SalesRankings}{SalesRank}[0]{Rank};
    }
    else
    {
        $sales_rank = $r->{SalesRankings}{SalesRank}{Rank};
    }

    $ranks{$gtin} = $sales_rank;
    sleep 5;
}

for my $gtin (sort { $ranks{$a} <=> $ranks{$b} } keys %ranks)
{
    print "$gtin: $ranks{$gtin}\n";
}
