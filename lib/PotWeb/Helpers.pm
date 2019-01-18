package PotWeb::Helpers;
use base 'Mojolicious::Plugin';

use strict;
use warnings;
use UUID::Tiny ':std';
use Data::UUID;

sub register {

    my ($self, $app) = @_;

    $app->helper(redis =>
	    sub { shift->stash->{redis} ||= Mojo::Redis2->new; });

    $app->helper(merge => sub {
        my ($self,$custData,$custLayout) = @_;
        my $dataOut;
        foreach my $items (@{$custLayout->{'layout'}}) {
                        my ($key,$type,$text,$value) = split(/,/,$items);
                        if ($custData->{$key}) {
                                $dataOut->{$key} = $custData->{$key};
                        } else {
                                $dataOut->{$key} = $value;
                        }
        }

        return $dataOut;
    });


	$app->helper(layout => sub {
        my ($self,$custData,$custLayout) = @_;
         foreach my $items (@{$custLayout}) {
                         my ($key,$type,$text,$value) = split(/,/,$items);
                         $custLayout->{$key} = $value;
                 }
        return $custLayout;
    });

    ## System Check Helper Functions

    $app->helper(uuid => \&_uuid);
		$app->helper(hex_uuid_to_uuid => \&_hex_uuid_to_uuid);

}

sub _uuid {
		## This function returns uuid and hex version of the same UUID

    my $self = shift;
    my $uuid_rand  = uuid_to_string(create_uuid(UUID_RANDOM));
    my $uuid_binary = create_uuid(UUID_SHA1, UUID_NS_DNS, $uuid_rand);
    my $hex;
		## Converts UUID to uppercase string

    my $uuid_string = $hex = uc(uuid_to_string($uuid_binary));

    $hex =~ tr/-//d;

    return ($uuid_string, $hex);
};

sub _hex_uuid_to_uuid {
	my ($self, $hex) = @_;
	my $ug = Data::UUID->new;
	my $uuid = $ug->from_hexstring($hex);
	$uuid = $ug->to_string($uuid);
	return $uuid;
};

1;